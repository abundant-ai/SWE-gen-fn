Ecto currently lacks a way to express a PostgreSQL CROSS JOIN LATERAL in the query DSL. Users can express LATERAL joins in some forms, but they cannot generate SQL of the form `CROSS JOIN LATERAL (...)` (or its equivalent semantics) when building queries that need a lateral subquery without an `ON` condition.

This becomes a problem for queries where the right side must reference columns from the left side and should behave like an unconditional join (i.e., rows from the left side are paired with all rows produced by the lateral subquery). In Postgres, this is expressed as `CROSS JOIN LATERAL` and is commonly used for patterns like selecting the “top N per group”, computing derived sets per row, or other correlated subqueries.

Ecto should allow constructing such queries via `Ecto.Query.join/5` and `from/2` join syntax, producing correct SQL for the PostgreSQL adapter.

Expected behavior:
- When a query is built with a lateral join that is explicitly marked as a cross join, Ecto should compile it successfully and the Postgres adapter should emit `CROSS JOIN LATERAL` in the generated SQL.
- The right side of the join must be allowed to reference bindings from the left side (normal lateral semantics).
- Because it is a cross join, no `ON ...` predicate should be required or emitted.

Actual behavior:
- Attempting to express this join either is not possible in the DSL, or it results in a different join type being generated (such as an inner/left lateral join), or it requires an `on:` clause/produces an `ON TRUE` style workaround instead of `CROSS JOIN LATERAL`.

Implement support for a dedicated cross lateral join in the query representation and in SQL generation, so that queries can explicitly request this join type and get the correct Postgres SQL output.