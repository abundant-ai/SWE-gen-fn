PostgREST currently rejects or misparses type casts in the `select` query parameter when the cast target type name contains underscores and/or digits, which prevents selecting expressions that cast to PostgreSQL array base types like `_int4` (the internal name for `int[]`).

For example, a request like:

```http
GET /tbl?select=oid_array::_int4
```

should be accepted and produce a normal 200 response with the cast applied, but at the moment the request fails during query parsing (the cast type token is not recognized as a valid type name) and results in an error response instead of returning data.

The query parameter parser that handles `select` expressions and PostgreSQL cast syntax (`::<type>`) needs to allow cast target identifiers that include underscores and numbers (e.g., `_int4`, `_numeric`, `my_type2`, `foo_bar1`). This should work anywhere a cast is allowed in a `select` expression, including casts on columns and computed expressions.

After the change, PostgREST should successfully parse and execute `select` expressions containing `::<type>` where `<type>` contains underscores and/or digits, without requiring bracket array syntax like `int[]` (which is not expected to be supported here).