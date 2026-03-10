PostgREST currently keeps retrying database connections when the configured `db-uri` is invalid or the PostgreSQL server is temporarily unavailable. This makes it hard to run PostgREST under process supervisors (e.g., systemd) in a “fail fast” mode, where an initial startup failure should terminate the process with a non-zero exit status so the supervisor can restart it.

Add a configuration option named `db-pool-automatic-recovery` that controls whether PostgREST should automatically recover/retry when it cannot establish or maintain database connections.

When `db-pool-automatic-recovery = true` (default), behavior should remain unchanged: PostgREST may keep retrying connections/recovering the pool as it does today.

When `db-pool-automatic-recovery = false`, PostgREST should fail fast instead of retrying:

- On startup, if PostgREST cannot establish the initial database connection using `db-uri` (e.g., invalid URI, DNS failure, connection refused, server down), it must terminate and exit with a non-zero status rather than looping/retrying.
- If the database becomes unavailable after startup in a way that would previously trigger automatic pool recovery/reconnection attempts, PostgREST should not engage in automatic recovery. Instead it should treat this as a fatal condition and terminate with a non-zero exit status (so an external supervisor can restart it).

The new option must be parsed from configuration in both boolean and numeric/string representations where applicable, and it must appear in the effective rendered configuration output with a default value of `true` when not explicitly set.

Example expected configuration behavior:

- With no explicit setting, `db-pool-automatic-recovery` is effectively `true`.
- With `db-pool-automatic-recovery = false`, starting PostgREST with a non-working `db-uri` should exit promptly with an error (not keep retrying).