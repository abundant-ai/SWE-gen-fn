When PostgREST reads configuration from the database (using role settings like `pgrst.<setting>`), it incorrectly parses settings whose values contain the `=` character. This happens because the code splits each setting on `=`, but it effectively splits on all `=` occurrences instead of only the first one, truncating the value.

This is user-visible when setting `pgrst.jwt_secret` to a JWKS or any string containing `=`. For example, after storing a value containing `=` in the database and then running `postgrest --dump-config`, the output shows a truncated `jwt-secret` value that ends right before the next `=`. This makes the dumped configuration invalid and causes runtime configuration to be wrong (e.g., JWT verification fails because the secret/JWKS is incomplete).

Reproduction example:
1) Configure PostgREST to read config from the database.
2) In PostgreSQL, set a reloadable setting to a value containing `=` (for instance `pgrst.jwt_secret = 'OVERRIDE=REALLY=REALLY=REALLY=REALLY=VERY=SAFE'` or a JSON/JWKS string that contains base64 segments with `=`).
3) Run `postgrest --dump-config` (or start PostgREST with DB config enabled).

Expected behavior:
- Database configuration values must be read in full, preserving all characters including any additional `=` characters after the first separator.
- `--dump-config` should print the complete value exactly as stored (properly quoted/escaped as usual), e.g. `jwt-secret = "OVERRIDE=REALLY=REALLY=REALLY=REALLY=VERY=SAFE"`.

Actual behavior:
- The value is cut off at the first subsequent `=` inside the value, so `jwt-secret` (and any other setting containing `=`) becomes truncated.

Fix requirement:
- Update the database config parsing logic so each `key=value` line is split only at the first `=` delimiter (producing exactly a key and the remainder as the value), rather than splitting on every `=`.
- Ensure this works both for ordinary values like `OVERRIDE=...` and for longer JSON/JWKS strings where `=` may appear in the middle of the value.
- Configuration precedence must remain correct: database-specific role settings (set per database) should override non-database-specific role settings when both are present, without altering the value contents.