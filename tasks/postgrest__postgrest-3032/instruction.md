Transaction-scoped settings are currently hard to understand in PostgreSQL logs and in `pg_stat_statements` because PostgREST generates SQL that parameterizes both arguments to `set_config`. This results in statements like:

```sql
select set_config($1, $2, true), set_config($3, $4, true), ...;
```

While PostgreSQL can optionally show the bound parameter values at higher verbosity (e.g., log line `DETAIL: parameters: $1 = 'search_path', $2 = '"test", "public"', ...`), this verbosity is often disabled in production, and `pg_stat_statements` does not include those parameter values. As a result, it’s unclear from the logged SQL which settings are being applied (e.g., `search_path`, `role`, `request.jwt.claims`, `request.method`, etc.).

Update the SQL generation for transaction-scoped settings so that the *setting name* (the first argument to `set_config`) is no longer parameterized and is instead embedded as a SQL string literal, since PostgREST fully controls these names. Only the setting values should remain parameterized. The generated SQL should look like:

```sql
select set_config('search_path', $1, true),
       set_config('role', $2, true),
       set_config('request.jwt.claims', $3, true),
       set_config('request.method', $4, true),
       ...;
```

This should improve readability in standard PostgreSQL logs and make statements more meaningful in `pg_stat_statements`.

Additionally, PostgREST previously supported “Legacy GUCs” behind a configuration option named `db-use-legacy-gucs`. That option should no longer exist: it must be removed from configuration parsing/normalization and from any displayed/serialized configuration output. Any behavior that depended on this flag should be updated so PostgREST no longer has a legacy mode for GUC naming; it should use the current GUC naming behavior unconditionally.

After these changes:
- Transaction-scoped `set_config` statements must show the setting keys directly in the SQL text.
- The number and ordering of parameters must correspond only to values (not keys).
- `db-use-legacy-gucs` must not be accepted as a valid configuration setting and must not appear in emitted configuration output.