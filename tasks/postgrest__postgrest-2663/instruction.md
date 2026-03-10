PostgREST’s database connection pool can keep connections alive indefinitely. Under certain workloads this causes practical issues: in the test suite it can lead to sporadic failures where a query plan that is expected to show zero buffer hits sometimes shows a non-zero “Shared Hit Blocks” value, consistent with reuse of warmed/shared buffers across long-lived pooled sessions. Separately, when the pool is starved (many requests waiting on slow queries) the system can behave poorly; having a way to recycle connections helps reduce long-lived session effects and makes pool behavior more predictable.

Add support for a new configuration option that limits how long a pooled database connection may live before being recycled: `db-pool-max-lifetime`. The setting should be configurable both via the config file and environment variable (`PGRST_DB_POOL_MAX_LIFETIME`). It must be reflected in the rendered/normalized configuration output alongside existing pool settings (e.g., `db-pool` and `db-pool-acquisition-timeout`).

Expected behavior:
- PostgREST accepts `db-pool-max-lifetime` as an integer duration in seconds.
- A default value is applied when the option is not explicitly set (use 1800 seconds).
- When configured, the connection pool enforces this maximum lifetime by recycling connections that exceed it (connections older than the configured lifetime should not be reused).
- Configuration round-tripping/printing should include `db-pool-max-lifetime` with the correct value in all relevant configuration outputs.

Misbehavior to fix:
- Without enforcing a maximum connection lifetime, long-lived pooled sessions can be reused in a way that makes query-plan buffer statistics non-deterministic across runs (e.g., a plan that should report `"Shared Hit Blocks": 0` sometimes reports a non-zero value like `39`). After implementing max lifetime recycling, this behavior should be stabilized so that plan buffer reporting in fresh sessions does not sporadically show unexpected shared hit blocks.

If invalid values are provided (e.g., non-integer or negative lifetimes), PostgREST should reject the configuration with a clear error rather than silently ignoring it.