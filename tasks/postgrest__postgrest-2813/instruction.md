PostgREST’s connection recovery behavior is problematic in several real-world failure modes, especially when using read replicas and when the database connection is forcibly terminated or misconfigured.

When PostgREST is connected to a read replica, LISTEN/NOTIFY cannot be used, so a common workaround is to force PostgREST to reconnect by terminating its backend connections (for example via `pg_terminate_backend`). This currently causes an awkward, non-graceful recovery sequence for incoming requests:

1) The first request after termination fails with an internal server error (HTTP 500) and a PostgreSQL error code `57P01` (message like `terminating connection due to administrator command`).
2) Only on a subsequent request does PostgREST return HTTP 503 (`PGRST001` / “Database client error. Retrying the connection.”), which then triggers/reflects recovery.
3) A third request finally succeeds (HTTP 200) after reconnection.

This behavior should be improved so that a forced termination that yields SQLSTATE `57P01` is treated as a transient availability problem and should start recovery immediately. The expected behavior is that `57P01` does not surface as a 500 in this scenario; instead it should be interpreted like a “database unavailable/reconnecting” situation (HTTP 503), so that recovery begins on the first failing request and the system returns to healthy operation without requiring an extra “probe” request.

Additionally, connection recovery timing should be consistent with the configured connection worker delay/backoff. In some scenarios (e.g., the database is down and then comes back), PostgREST can appear to recover on the next incoming request before the connection worker’s delay/backoff has elapsed, effectively bypassing the intended delay behavior. Requests during the recovery window should not prematurely succeed just because a new request arrived; they should respect the recovery state and continue returning HTTP 503 until recovery has completed according to the configured worker/backoff behavior.

Finally, PostgREST should not endlessly retry in cases that are clearly non-recoverable configuration/authentication errors. In particular, if the PostgreSQL client error indicates `fe_sendauth: no password supplied`, PostgREST should treat this as fatal and stop retrying the connection (i.e., it should “die” rather than entering a retry loop), because this error indicates missing credentials rather than a transient connectivity problem.

Overall expected outcomes:
- A connection termination resulting in SQLSTATE `57P01` should be handled as a transient outage and should yield an HTTP 503-style response that triggers immediate recovery, rather than returning HTTP 500 first and requiring multiple requests to fully recover.
- During database recovery, request handling should respect the recovery worker timing/backoff so that requests are consistently rejected with HTTP 503 while recovery is in progress, rather than being able to succeed early due to a new request triggering an on-demand reconnect.
- When the database connection fails with `fe_sendauth: no password supplied`, PostgREST should exit instead of retrying indefinitely.