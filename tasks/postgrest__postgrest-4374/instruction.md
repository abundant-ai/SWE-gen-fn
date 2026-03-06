PostgREST’s `log-query` configuration is currently too limited and awkward to configure: it requires string values (historically values like `disabled`/`enabled`/`full`) and, even when set to the most verbose mode (`log-query=full`), it does not consistently log all SQL statements that PostgREST generates for a request.

Two problems need to be fixed:

1) `log-query` should be a boolean configuration value.

- The configuration option `log-query` must accept boolean values and be represented as a boolean in PostgREST’s effective configuration output.
- Default behavior should be `log-query = false`.
- The system should treat string inputs like `"false"` (and numeric/boolean equivalents, if supported elsewhere in the config system) consistently as false, so that producing the normalized/effective config renders `log-query = false`.
- This is a breaking change: older string modes should no longer be required for configuration.

2) When SQL query logging is enabled, PostgREST should log all generated SQL statements for each request.

When `log-query` is enabled (true), PostgREST should emit logs for every SQL statement it generates as part of handling a request, not just the main API query. This includes:

- Transaction-scoped settings statements, including those generated for pre-request processing.
- The `EXPLAIN` query generated when a request uses `Prefer: count=estimated`.
- Any other SQL statements PostgREST generates as part of planning/execution for a request (the goal is “log all generated queries”).

Currently, enabling the most verbose logging does not log these auxiliary/generated queries, making it hard to fully observe what SQL was executed.

After the change:
- Setting `log-query = true` must result in logs that include the full set of SQL statements generated for a request (including the items listed above).
- Setting `log-query = false` must result in no SQL query logs.

The effective configuration output (the normalized config PostgREST prints/exports) must reflect `log-query` as a boolean (e.g., `log-query = false` by default, and `log-query = false` when configured with equivalent false-y values).