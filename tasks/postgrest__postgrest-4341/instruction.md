When PostgREST is configured with `log-query=full`, it should log *all* SQL statements it generates and sends to PostgreSQL for servicing a request. Currently, some generated statements are missing from the logs, which makes `log-query=full` incomplete and prevents users from auditing/debugging the exact SQL that was executed.

The missing statements include:

1) Transaction-scoped settings statements (the per-request `SET LOCAL ...` / transaction GUC setup that PostgREST issues as part of its transaction handling). These must be logged whenever `log-query=full` is enabled.

2) Any SQL generated for a pre-request function (when a pre-request hook is configured). The SQL used to run the pre-request function must also appear in the query logs under `log-query=full`, along with any transaction-scoped settings that are applied for that pre-request execution.

3) The `EXPLAIN` statement that PostgREST generates when a request uses `Prefer: count=estimated`. When this preference is present and PostgREST performs an estimated count workflow, `log-query=full` must include the generated `EXPLAIN` query in the logs in addition to the main query.

Expected behavior: with `log-query=full`, for a single HTTP request, the logs should contain every generated SQL statement in the order they are executed, including any preliminary statements (transaction-scoped settings, pre-request function call SQL) and auxiliary statements (such as the `EXPLAIN` used for estimated counts).

Actual behavior: even with `log-query=full`, the logs omit transaction-scoped settings and omit the pre-request-related SQL; and in `Prefer: count=estimated` scenarios, the generated `EXPLAIN` statement is not logged.

Fix this so that enabling `log-query=full` reliably logs the complete set of SQL statements generated and executed for the request lifecycle, including the pre-request phase and the estimated-count `EXPLAIN` query.