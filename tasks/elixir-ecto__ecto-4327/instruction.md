When building Ecto queries that use `select_merge/3` with interpolated map keys, Ecto incorrectly treats the interpolated key as a query parameter and sends it to the database. This breaks when the interpolated key is not a binary (for example, an atom), because the generated SQL selects the key as a literal/parameter and the database adapter attempts to encode it.

For example, the following should work and return a map with an atom key turned into a string key (or otherwise preserve the intended key) without sending the key itself as a database parameter:

```elixir
"users"
|> select([u], %{})
|> select_merge([u], %{^:test => "1"})
|> limit(1)
|> Repo.one()
```

Currently, this query errors at runtime with:

`(DBConnection.EncodeError) Postgrex expected a binary, got :test`

and the logged SQL shows Ecto is selecting the key itself (e.g. `SELECT 'test' FROM ...`) instead of treating it purely as a compile/runtime-only construct for building the result map.

Dynamic/interpolated map keys in `select`/`select_merge` should not be sent to the database, because they do not affect the database query semantics (they only shape the returned Elixir map). Instead, Ecto should validate interpolated map keys at the time the select expression is built and store them directly in the query AST/struct, so they never become DB parameters.

The behavior should support dynamically setting non-binary keys at runtime at least for basic literal key types such as atoms, strings, integers/floats (and similar simple scalar literals). If an interpolated key is a composite type (such as a tuple, list, or map), Ecto should reject it with a clear `Ecto.Query.CompileError` explaining that only basic literal types are supported for interpolated map keys.

This must work consistently for both outer queries and when select expressions appear in subqueries/CTEs, with the constraint that subqueries/CTEs should continue to enforce their existing key restrictions (for example, only allowing atom keys where applicable) while still avoiding sending interpolated keys to the database.