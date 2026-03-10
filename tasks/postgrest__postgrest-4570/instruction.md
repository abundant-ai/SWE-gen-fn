Server-Timing durations reported by PostgREST are inaccurate. When Server-Timing is enabled and a request is executed, the values emitted in the `Server-Timing` response header do not correctly reflect the actual elapsed time spent in each measured phase, causing durations to be misleading (e.g., not matching wall-clock time or being systematically offset/incorrectly computed).

Fix the Server-Timing implementation so that:

- The `Server-Timing` response header reports correct `dur=` values (in milliseconds) for the measured phases of handling a request.
- Durations must be computed from the correct start/end instants for each phase, not from an unrelated timestamp or a reused baseline that skews results.
- The reported durations should be consistent with real elapsed time: for example, if an endpoint intentionally sleeps for ~500ms on the server side, the relevant timing(s) in `Server-Timing` should reflect approximately that magnitude (allowing for normal overhead/jitter).
- The header must remain parseable according to the `Server-Timing` format, and timing entries must remain stable enough for downstream tooling that parses `Server-Timing`.

Reproduction example:

1) Start PostgREST with Server-Timing enabled.
2) Call an endpoint that deterministically takes a known amount of time (e.g., an RPC that sleeps for 0.5 seconds).
3) Inspect the `Server-Timing` response header.

Expected: at least one timing entry (or the appropriate phase entry) should show a duration close to 500ms (plus small overhead), and other phases should have plausible non-negative durations.

Actual: the `dur=` values are inaccurate (e.g., significantly different from the known runtime or otherwise miscomputed), making Server-Timing unsuitable for profiling/monitoring.

Implement the fix so that all Server-Timing durations accurately represent the request lifecycle timing they claim to measure, without regressions in header formatting or request handling.