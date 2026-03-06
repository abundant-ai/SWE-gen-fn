When PostgREST is configured to log SQL via `PGRST_LOG_QUERY=main-query` (with `PGRST_LOG_LEVEL=debug`), requests that serve the OpenAPI document are not logging any of the SQL statements they execute.

Reproduction:
- Start PostgREST with `PGRST_LOG_QUERY=main-query` and `PGRST_LOG_LEVEL=debug`.
- Request the OpenAPI endpoint, e.g. `curl -I http://localhost:3000/` (or a normal GET to `/`).

Actual behavior:
- The HTTP request is logged, but none of the SQL generated for the OpenAPI response is logged. Users only see the access log line (e.g. `"HEAD / HTTP/1.1" 200 ...`) and no SQL output, even though OpenAPI generation executes multiple SQL statements.

Expected behavior:
- OpenAPI-related SQL should be logged the same way as other “main-query” SQL statements are logged. In particular, when OpenAPI generation runs multiple internal SQL statements (currently three statements for the default OpenAPI mode, and an additional statement when `openapi-mode = "follow-privileges"`), those statements must appear in the SQL query logs under `log-query=main-query`.

The bug appears to be that OpenAPI query execution bypasses the normal query logging mechanism (it effectively logs `mempty` / nothing for the SQL text), so the logger never receives the actual SQL to print.

Fix the OpenAPI query execution path so that it produces a loggable SQL string and emits it through the same dynamic-statement logging mechanism used for other queries. The logged output should include the actual SQL text executed for OpenAPI generation (including the combined text if multiple statements are executed as part of generating the OpenAPI document), so that enabling `PGRST_LOG_QUERY=main-query` reliably logs OpenAPI SQL.