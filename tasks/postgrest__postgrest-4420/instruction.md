When PostgREST is started with the `db-pre-config` setting enabled, it may attempt to call a pre-config PostgreSQL function name that comes from configuration (e.g., environment variable `PGRST_DB_PRE_CONFIG`). If this configured function name is a PostgreSQL reserved word (for example `true`), PostgREST currently generates invalid SQL by inserting the function name unquoted into a query, causing PostgreSQL to error during startup.

A common failure looks like a PostgreSQL error similar to:

```
ERROR:  syntax error at or near "true" ...
... JOIN true() _ ON TRUE
```

This leads to PostgREST exiting on startup with a confusing database syntax error.

The pre-config function name must be treated as an SQL identifier and safely/consistently quoted when PostgREST constructs the SQL that calls it. After the fix, setting `PGRST_DB_PRE_CONFIG` (or the equivalent config key) to a value that happens to be a reserved word (e.g. `true`) should no longer cause a SQL syntax error solely due to the function name being unquoted. Instead, PostgREST should be able to proceed to the next stage (e.g., if the function doesn’t exist, it should fail in a clearer/expected way rather than with a raw SQL parse error).

Reproduction example:
1) Configure PostgREST with `PGRST_DB_PRE_CONFIG=true` (or `db-pre-config = "true"` in config).
2) Start PostgREST against a PostgreSQL instance.
3) Observe that PostgREST fails during startup because it tries to execute SQL containing `true()`.

Expected behavior:
- PostgREST must quote the configured pre-config function identifier when generating SQL so that reserved words (and other special identifier cases) do not break SQL parsing.
- Startup should not fail with `syntax error at or near "true"` due to the pre-config function name.

Actual behavior:
- Startup fails with a PostgreSQL syntax error because the function name is interpolated as `true()` (or another reserved word) without identifier quoting.