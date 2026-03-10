PostgREST reports inaccurate elapsed times in both its logs and its `Server-Timing` response header. This is most visible for long-running operations (e.g., calling an RPC that sleeps), where the `transaction` duration is far smaller than the real wall-clock time, and schema cache timing logs can claim durations well below an intentional sleep.

When `PGRST_SERVER_TIMING_ENABLED=true`, requests like:

```
curl -i localhost:3000/rpc/sleep?seconds=4
```

should return a `Server-Timing` header whose `transaction;dur` is close to the actual request time (~4000 ms), but it currently can return values off by orders of magnitude (e.g., `transaction;dur=47.1` for a 4-second sleep).

Similarly, when forcing a schema cache query to sleep using `PGRST_INTERNAL_SCHEMA_CACHE_QUERY_SLEEP=1000`, PostgREST logs a message like:

`Schema cache queried in X milliseconds`

The logged value `X` should be greater than or equal to 1000 ms (allowing for overhead), but it can incorrectly report much smaller values (e.g., ~31.9 ms).

The timing values must be derived from a monotonic, wall-clock-like duration measurement so that:

- `Server-Timing` durations are in milliseconds and scale correctly for both short and long requests.
- Logged durations (including schema cache query/load timings) are consistent with real elapsed time, including cases where an intentional sleep is introduced.
- Longer waits (e.g., `seconds=100`) should not drift significantly from actual elapsed time; the `transaction` duration should be approximately 100000 ms (with small overhead), not e.g. 112000 ms.

Fix the internal timing measurement used for request timing and schema cache timing so that the reported milliseconds are accurate and consistent across platforms (including macOS).