PostgREST can exhibit very high CPU usage when the database connection pool is saturated (e.g., many concurrent requests calling a slow/unoptimized function). In these scenarios, requests wait on the pool up to `db-pool-acquisition-timeout` (default 10 seconds), and the server can spend excessive CPU time while the pool is starved. Additionally, after updating the underlying pool implementation to use hasql-pool 0.10, PostgREST needs to expose a way to limit how long idle connections are kept around, restoring behavior similar to the older `db-pool-timeout` setting.

Implement support for a new configuration option named `db-pool-max-idletime` that controls the maximum idle time (in seconds) of a PostgreSQL connection in the pool. The option must be available through the same configuration mechanisms as existing `db-pool-*` settings (config file and environment variables), using the environment variable name `PGRST_DB_POOL_MAX_IDLETIME`.

Expected behavior:
- When `db-pool-max-idletime` is not set explicitly, it must default to `30` seconds.
- When set, its value must be reflected in the effective configuration output/normalization the same way other numeric `db-pool-*` options are (e.g., it should round-trip through config parsing/printing like `db-pool`, `db-pool-acquisition-timeout`, `db-pool-max-lifetime`).
- When constructing the database connection pool, PostgREST must pass this idle-time limit to the pool so that connections idle longer than this value are eligible to be closed/recycled.

This change is required while migrating to hasql-pool 0.10, which changed pool configuration arguments; PostgREST must compile and run correctly against hasql-pool 0.10 while preserving existing pool-related settings and adding `db-pool-max-idletime`.

Reproduction scenario motivating the change:
- Configure a small pool (e.g., `db-pool = 1`) and send many concurrent requests to a slow endpoint/query so that most requests must wait for a connection.
- With the pool starved, PostgREST should avoid pathological CPU behavior and should respect pool timeouts/limits; adding `db-pool-max-idletime` ensures idle connections don’t linger indefinitely and restores prior ability to control connection lifetimes under load.

If invalid values are provided (non-numeric or negative), configuration loading should fail in the same manner as it does for other numeric pool settings.