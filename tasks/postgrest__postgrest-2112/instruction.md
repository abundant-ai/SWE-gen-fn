PostgREST currently cannot be run in a true “zero/low config” mode, and its configuration loading behavior has several inconsistencies when `db-config` (in-database configuration) is enabled.

Problem 1: `db-uri` is treated as mandatory even though PostgREST uses libpq and should be able to connect using standard libpq defaults / `PG*` environment variables.

When running without an explicit `db-uri` (e.g., not setting `PGRST_DB_URI` and not providing `db-uri` in the config file), PostgREST should still be able to start and attempt to connect using libpq defaults (including `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`, etc.). Today, startup fails early because `db-uri` is required.

Problem 2: `db-schemas` should default to `public` so that in-database configuration can work without requiring a base config file to specify schemas.

When the user does not specify `db-schemas` (or the legacy `db-schema` alias), PostgREST should behave as if `db-schemas = "public"`. This is necessary so that enabling database configuration does not require a minimal config file just to pass validation.

Problem 3: `db-anon-role` should be optional, defaulting to “no anonymous access”, and anonymous requests should be blocked when it’s not set.

Currently PostgREST requires `db-anon-role`. Instead, it should be valid to omit it entirely. In that case:

- PostgREST must still start successfully.
- Requests without authentication (no JWT / no role) must be rejected rather than treated as anonymous.
- The rejection should be a clear authorization failure (e.g., an HTTP error response indicating authentication is required), rather than a crash or a misleading database error.

Problem 4: Reading secrets from stdin is broken when `db-config=true` because config reload causes the secret source to be consumed more than once.

If `jwt-secret` is configured using external file syntax pointing to stdin (e.g., `jwt-secret = "@/dev/stdin"` or equivalent behavior via env/config indirection), then PostgREST can successfully read it once at initial load, but when `db-config=true` triggers a config reload (such as during startup reloading from the database, or via runtime reload mechanisms), the secret becomes the empty string because stdin has already been consumed.

Reproduction example:

```bash
echo "test" | PGRST_DB_CONFIG=false postgrest ... --dump-config <config>
# expected: jwt-secret = "test"

echo "test" | PGRST_DB_CONFIG=true postgrest ... --dump-config <config>
# currently: jwt-secret = "" (wrong)
# expected: jwt-secret = "test"
```

The same issue appears when triggering reload via signals (e.g., schema/config reload), where subsequent reload attempts cannot re-read stdin-backed secrets.

Expected behavior:

- PostgREST should either reliably preserve externally loaded secret values across config reloads when `db-config=true` (and during reload signals), or it should explicitly reject/disable stdin-based secret sources in a clear way (e.g., startup error explaining that stdin cannot be used for reloadable secrets). The current behavior of silently turning the secret into an empty value after reload is incorrect.

Additionally, when `db-config=true`, schema reload actions may reload configuration (from both the database and the config file) and therefore re-evaluate external file directives for settings like `jwt-secret`. This must be consistent and not lead to surprising partial reloads or secret loss.

Overall, PostgREST should be able to start with no explicit config values for `db-uri`, `db-schemas`, and `db-anon-role` (using defaults and/or env vars), while still enforcing safe behavior (no anonymous access unless explicitly configured) and ensuring that configuration reload does not corrupt `jwt-secret` when external sources are used.