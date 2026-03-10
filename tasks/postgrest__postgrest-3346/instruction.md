In-database configuration values set via Postgres role GUCs are not being applied for some server-related settings. In particular, setting `pgrst.server_trace_header` (and likewise `pgrst.server_cors_allowed_origins`) on the authenticator role does not take effect when PostgREST starts, even though the same values work when provided via the config file or environment variables.

Reproduction:
1) Configure PostgREST to use an authenticator role (e.g. `postgrest_test_authenticator` / `db_config_authenticator`) and enable loading config from the database (`db-config = true`).
2) In Postgres, set the GUCs on the authenticator role, e.g.

```sql
ALTER ROLE postgrest_test_authenticator SET pgrst.server_trace_header = 'X-Y';
ALTER ROLE postgrest_test_authenticator SET pgrst.server_cors_allowed_origins = 'http://origin.com';
```

3) Start PostgREST using that authenticator.

Actual behavior:
- PostgREST ignores these in-database values for `server-trace-header` and `server-cors-allowed-origins` (they remain at defaults or at the values from file/env), even though other `pgrst.*` settings loaded from the database are applied.

Expected behavior:
- When `db-config` is enabled, PostgREST must load `pgrst.server_trace_header` and `pgrst.server_cors_allowed_origins` from the database just like other reloadable `pgrst.*` settings.
- Database-specific overrides must be respected: if a setting is specified both as `ALTER ROLE ... SET ...` and `ALTER ROLE ... IN DATABASE <dbname> SET ...`, the database-specific value should win for that database.
- Settings for other databases (i.e., `IN DATABASE other`) must not affect the running instance.
- Unknown `pgrst.*` keys present in role settings should be ignored rather than causing failures.

Implement whatever changes are needed so these two config keys are recognized as reloadable in-db config values and are correctly parsed/loaded into `AppConfig`, consistent with how PostgREST already handles other `pgrst.*` in-database settings.