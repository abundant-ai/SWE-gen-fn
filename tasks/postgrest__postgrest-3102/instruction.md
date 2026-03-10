PostgREST supports reading some configuration values from PostgreSQL (role settings and per-database role settings under the `pgrst.*` namespace) when database configuration is enabled. However, the `jwt-cache-max-lifetime` setting currently cannot be provided via in-database config even though it is a supported PostgREST configuration parameter. As a result, setting `pgrst.jwt_cache_max_lifetime` on the authenticator role (or overriding it for a specific database) is ignored, and PostgREST continues using the file/env/default value instead.

Add support for `jwt-cache-max-lifetime` as an in-database configuration option.

When database configuration is enabled and the database contains settings like:

```sql
ALTER ROLE db_config_authenticator SET pgrst.jwt_cache_max_lifetime = '3600';
ALTER ROLE db_config_authenticator IN DATABASE <dbname> SET pgrst.jwt_cache_max_lifetime = '7200';
```

PostgREST should load this value from the database (including honoring the per-database override for the current database) and expose it as the effective runtime configuration value `jwt-cache-max-lifetime`.

Expected behavior: the effective configuration output/representation includes `jwt-cache-max-lifetime` with the value sourced from the database settings (e.g., `3600` by default and `7200` when overridden for the current database).

Actual behavior: `pgrst.jwt_cache_max_lifetime` is ignored as an in-database option, so `jwt-cache-max-lifetime` does not reflect the database-provided value.

The change should ensure `jwt-cache-max-lifetime` is treated as a reloadable in-database option in the same way as other JWT-related in-database settings (such as `jwt-aud`, `jwt-secret`, `jwt-secret-is-base64`, and `jwt-role-claim-key`).