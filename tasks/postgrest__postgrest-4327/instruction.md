When PostgREST is configured to log SQL queries via the `log-query` setting, it currently fails to log the `EXPLAIN` statement that is executed to compute an estimated total count.

Reproduction:
1) Start PostgREST with `PGRST_LOG_LEVEL=info` and `PGRST_LOG_QUERY=main-query` (and a database with a table like `projects`).
2) Perform a request that triggers estimated counts, e.g.:

```bash
curl "http://localhost:3000/projects" -H "Prefer: count=estimated" -i
```

Actual behavior:
- The main SQL query is logged.
- An additional `EXPLAIN` query is executed internally to obtain an estimated count, but this `EXPLAIN` query is not logged, even though query logging is enabled.

Expected behavior:
- When `Prefer: count=estimated` causes PostgREST to run an extra `EXPLAIN` query, that `EXPLAIN` query must also be emitted to the logs under the same conditions as other logged queries.
- In particular, with `PGRST_LOG_QUERY=main-query` (and equivalent configuration via the config file), the server logs should include the SQL text for the `EXPLAIN` statement used for the estimated count, not only the main data query.

Implement the missing logging so that any `EXPLAIN` query executed for estimated-count pagination is logged consistently with the existing `log-query` behavior and log level settings.