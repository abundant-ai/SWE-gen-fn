Some runtime observations related to the database connection pool are never logged, even when running with verbose logging. In particular, the observations `PoolRequest` and `PoolRequestFullfilled` are currently treated as metrics-only and end up producing no log output (effectively an empty message), because the logger intercepts these events and prevents them from going through the normal observation-to-message path.

This leads to two problems:

1) When the system is configured to log at debug level (or higher verbosity), users expect to see pool activity, but no log lines are emitted for these two events.

2) The observation-to-text conversion for these events currently results in an empty message, which is risky because it can produce blank log lines if the normal logging path is used elsewhere (and it makes the behavior inconsistent with other observations that always have a message).

Update observation logging so that:

- `observationMessage PoolRequest` returns a non-empty human-readable message indicating that PostgREST is trying to borrow a connection from the pool.
- `observationMessage PoolRequestFullfilled` returns a non-empty human-readable message indicating that a connection has been borrowed from the pool.
- When the logger receives `PoolRequest` or `PoolRequestFullfilled`, it should emit these messages only when the configured log level is `debug` or more verbose. At lower log levels, these pool observations should not be logged.

After the change, running PostgREST with debug logging enabled and handling requests should produce debug log entries for pool acquisition attempts and successful acquisition, and it should never emit empty/blank log lines for these observations.