PostgREST’s database connection pool no longer times out idle connections (regression since v10.1.0), which can cause two serious production problems.

1) Memory growth with large pools: PostgreSQL backend processes for idle pooled connections can retain memory (e.g., growing catalog caches) and not release it, so a large `db-pool` can gradually consume significant RAM.

2) High connection latency spikes: some deployments see requests become slow after a period of inactivity. The pattern is that the first request after idling can take tens of seconds, while subsequent requests are fast again. Increasing `PGRST_DB_POOL_TIMEOUT` currently prolongs the time before latency regresses, indicating the connection initialization/re-initialization is involved.

The server should again support an idle connection timeout for the database pool via the `db-pool-timeout` / `PGRST_DB_POOL_TIMEOUT` configuration.

Expected behavior:
- There is a `db-pool-timeout` configuration value that controls how long an unused/idle connection may remain in the pool before being closed.
- The default `db-pool-timeout` should be 3600 seconds (1 hour), so idle connections are eventually recycled to mitigate long-term memory growth, while avoiding overly frequent reconnects that can create latency spikes.
- When PostgREST prints/exports its effective configuration (e.g., for config inspection/output), `db-pool-timeout` should appear and reflect the default value of `3600` unless explicitly overridden.
- The configuration should continue to accept an explicit override through environment variable `PGRST_DB_POOL_TIMEOUT` and/or the corresponding config setting.

Actual behavior:
- On versions affected by the regression, idle connections do not time out, which can lead to persistent idle connections consuming increasing memory.
- Users experiencing slow “first request after idle” behavior cannot reliably mitigate it with a sensible default timeout, and previously working expectations around `db-pool-timeout` no longer hold.

Fix the configuration and runtime behavior so that `db-pool-timeout` is present again and defaults to 3600 seconds, and ensure the pool honors it by closing idle connections after the configured duration.