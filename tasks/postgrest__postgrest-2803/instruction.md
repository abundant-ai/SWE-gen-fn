PostgREST supports “in-database configuration” by reading settings (GUCs with the `pgrst.*` prefix) from the database, but today this typically requires SUPERUSER/CREATEROLE to change role attributes. Add support for an additional configuration hook called `db-pre-config` that lets an administrator specify a database function to run before PostgREST reads configuration from the database, so that the function can set `pgrst.*` settings dynamically (e.g., with `set_config`).

A new configuration option `db-pre-config` must be accepted from both the config file and environment variables (as `PGRST_DB_PRE_CONFIG`). It should default to an empty value (disabled).

When `db-config` is enabled and `db-pre-config` is set to a non-empty function name (schema-qualified string like `postgrest.pre_config`), PostgREST should execute that function as part of startup/reload configuration retrieval, before collecting the `pgrst.*` settings from the database. The function returns `void`; it is used only for its side effects (setting GUCs such as `pgrst.db_schemas`, `pgrst.jwt_role_claim_key`, `pgrst.db_anon_role`, `pgrst.db_tx_end`, etc.).

Example desired usage:

```sql
create or replace function postgrest.pre_config()
returns void as $$
begin
  if current_user = 'other_authenticator' then
    perform
      set_config('pgrst.db_schemas', 'schema1, schema2', true),
      set_config('pgrst.jwt_role_claim_key', '."other"."pre_config_role"', true),
      set_config('pgrst.db_anon_role', 'pre_config_role', true),
      set_config('pgrst.db_tx_end', 'rollback-allow-override', true);
  end if;
end $$ language plpgsql;
```

Expected behavior:

- With `db-config = true` and `db-pre-config` configured, a subsequent config load should reflect values established by the hook function (including changes that depend on `current_user` / connection role).
- If `db-pre-config` is empty, no hook is executed and behavior remains unchanged.
- The configuration dump/introspection output should include the new `db-pre-config` field and show its configured value.
- Whitespace/quoting normalization should match existing config behavior (e.g., schema lists normalized consistently; the configured `db-pre-config` function name should be preserved as a string).

Currently, without this feature, users who cannot change role attributes cannot implement dynamic in-database configuration, and PostgREST has no place to run a “pre-configuration” SQL action before reading `pgrst.*` settings, so settings derived from a hook function are not applied.