Several query requests can fail or behave incorrectly due to name collisions between user schema identifiers and PostgREST’s internally generated SQL identifiers.

When querying a table that has a column named `count`, PostgREST should treat `count` as a regular column reference and must not confuse it with the built-in `pg_catalog.count` aggregate. A request like:

```http
GET /has_count_column
```

should succeed with HTTP 200, but currently the generated SQL can incorrectly resolve `count` as the aggregate function in some contexts, leading to query errors.

Similarly, when querying a table that has a column named `t`, PostgREST must not conflict with its internal table aliasing (commonly `t`) used in generated SQL. A request like:

```http
GET /clashing_column?select=t
```

should also succeed with HTTP 200, but currently can fail due to ambiguous/incorrect identifier resolution caused by alias/column name collision.

Fix the query builder so that user-provided column names that match internal aliases or common SQL function names are always correctly qualified/quoted such that:
- Selecting a column literally named `t` returns that column rather than colliding with internal aliases.
- Referencing a column literally named `count` is treated as an identifier, not as the `count()` aggregate.

These fixes should not change unrelated query semantics: requesting a nonexistent table (e.g. `GET /faketable`) must still return HTTP 404.