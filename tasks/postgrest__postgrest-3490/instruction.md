PostgREST readiness reporting is unreliable during schema cache reloads, which makes IO/integration tests flaky on slow or overloaded systems.

When the schema cache is reloading (for example after triggering a reload via an RPC like `POST /rpc/notify_pgrst`), the admin readiness endpoint (`GET /ready`) should not report the service as ready. Instead, while schema cache loading is in progress, `GET /ready` must return HTTP 503 (pending/not ready). Once the reload completes, `GET /ready` should return HTTP 200.

Currently, readiness can incorrectly appear as ready too early (or tests have to rely on fixed sleeps to “wait long enough”), leading to failures on loaded machines. The desired behavior is that clients can poll `/ready` and reliably detect the pending state without using arbitrary sleep durations.

Additionally, a true failure state should be reflected distinctly: if PostgREST encounters an internal failure that prevents it from being ready (e.g., an unrecoverable startup/runtime error affecting readiness), `GET /ready` should return HTTP 500.

The fix must ensure these behaviors:

- After a schema-cache reload is initiated, `/ready` transitions to and remains at HTTP 503 while the schema cache is loading.
- Requests that depend on schema cache (such as requests involving resource embedding like `GET /tpopmassn?select=*,tpop(*)`) should wait until the schema cache reload finishes and then succeed (HTTP 200), without requiring callers/tests to use fixed sleep delays.
- `/ready` returns HTTP 500 when readiness cannot be achieved due to an actual failure condition (distinct from the temporary “pending” state).

A practical reproduction scenario is:

1) Start PostgREST with schema caching enabled on a large schema and a small DB pool.
2) Trigger a schema cache reload (e.g., `GET /rpc/notify_pgrst` returning 204).
3) Immediately poll `GET /ready` and observe that it returns 503 during the reload.
4) Then perform a schema-cache-dependent request (e.g., an embedding query) and verify it completes successfully once the reload is done.

Right now, under load, the system requires timing assumptions (sleep) and can return the wrong readiness state, causing intermittent failures. The goal is to make readiness and request waiting deterministic by using `/ready` pending/fail semantics rather than timing-based sleeps.