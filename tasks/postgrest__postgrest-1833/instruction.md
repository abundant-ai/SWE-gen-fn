PostgREST’s database introspection model currently stores a foreign key directly on the `Column` type (via a field like `colFK`). This is incorrect because a single column can participate in multiple foreign keys, and it also forces additional filtering logic for internal foreign keys. As a result, the in-memory structure used to generate metadata (including OpenAPI output) is harder to reason about and can represent relationships inaccurately.

Update the database structure types and related logic so that `Column` no longer has a single foreign-key field. Foreign keys should instead be represented as a collection associated at the table/relationship level (e.g., `colFKs`/relationships list) such that multiple foreign keys referencing the same column are supported without requiring special filtering of “internal” foreign keys.

While making this change, do not break the current OpenAPI output: embedding/relationship discovery used by OpenAPI generation must continue to produce the same schema relationships as before.

Additionally, `pgVersion` should no longer be stored inside the `DbStructure` value. PostgreSQL version should be retrieved with `getPgVersion` and stored in application state, and components that previously depended on `DbStructure` containing the version must be updated to read it from `AppState` instead. The following behaviors must work together:

- `getDbStructure` should still load the database structure without requiring or embedding PostgreSQL version information.
- `getPgVersion` should still return the actual server version, and callers should be able to store it via `AppState.putPgVersion`.
- Applications that initialize `AppState` and then call `AppState.putDbStructure` and `AppState.putPgVersion` must continue to operate correctly, including when building OpenAPI output.

After the refactor, relationship handling must correctly support multiple foreign keys for the same column, and the removal of the single `Column` foreign key field must not cause missing or incorrect relationships in generated API metadata.