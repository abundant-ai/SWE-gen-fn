When PostgREST is run behind a PostgreSQL connection pooler configured for transaction or statement pooling (e.g., PgBouncer in transaction mode), requests can fail with PostgreSQL error code 42P05 and message `prepared statement "0" already exists`. This happens because prepared statements can leak across logical sessions in these pooling modes, causing name collisions when a connection is reused.

PostgREST needs to support transaction/statement pooling by allowing prepared statements to be disabled. Introduce/ensure a configuration option named `db-prepared-statements` that controls whether PostgREST uses prepared statements for database interactions. When `db-prepared-statements` is set to false, PostgREST must execute its database operations without using prepared statements, so that repeated requests through a transaction/statement pooler do not trigger the `42P05 prepared statement "0" already exists` error.

Additionally, when this error does occur (for example, if a user runs with prepared statements enabled against a transaction/statement pooler), the returned error response should include a helpful hint explaining that the pooler mode is incompatible with prepared statements and advising to either switch the pooler to session mode or disable prepared statements via `db-prepared-statements = false`.

Expected behavior:
- With PgBouncer (or similar) in transaction or statement pooling mode and `db-prepared-statements = false`, normal API requests should succeed without raising `42P05`.
- If `db-prepared-statements` remains enabled and the backend reports `42P05 prepared statement "0" already exists`, the client-visible error must include a hint pointing to `db-prepared-statements = false` and/or using session pooling.

Actual behavior to fix:
- PostgREST fails under transaction/statement pooling with `{"code":"42P05","message":"prepared statement \"0\" already exists"}` and provides no actionable guidance, and/or does not offer a way to avoid prepared statements in this mode.
