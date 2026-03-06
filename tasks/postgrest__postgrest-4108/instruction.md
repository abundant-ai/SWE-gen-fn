PostgREST startup can fail when `db-extra-search-path` is configured as an empty string to indicate “no extra schemas”. In this situation, PostgREST throws a parsing/config error and exits instead of treating the empty value as a valid configuration meaning “no extra search path entries”. This is a regression reported against v13 where omitting `db-extra-search-path` defaults it to `"public"`, but some deployments don’t have a `public` schema and need to explicitly configure the search path.

When `db-extra-search-path = ""` (or the equivalent environment configuration) is used, PostgREST should successfully start and behave as if there are no extra search path schemas beyond those implied by `db-schemas` (and whatever base search-path behavior PostgREST normally applies). An empty `db-extra-search-path` must not be treated as a syntax error, and it must not be silently coerced to `"public"`.

Additionally, when PostgREST fails while loading the schema cache (e.g., due to search-path/schema-related issues), the error log should include the effective values of both `db-schemas` and `db-extra-search-path` so operators can diagnose misconfiguration. The log output for schema cache load failures should clearly show these two configuration values as they were interpreted by the server at runtime.

Reproduction example:
- Configure PostgREST to use only non-`public` schemas via `db-schemas`.
- Set `db-extra-search-path` to an empty string.
- Start PostgREST.

Expected behavior:
- Server starts successfully (no parse/config error triggered solely by an empty `db-extra-search-path`).
- If schema cache loading fails for other reasons, the emitted error includes both `db-schemas` and `db-extra-search-path` values.

Actual behavior:
- With `db-extra-search-path = ""`, PostgREST fails to start due to a parsing/config error.
- On schema cache load failures, logs do not reliably provide enough context about `db-schemas`/`db-extra-search-path` to diagnose the issue.