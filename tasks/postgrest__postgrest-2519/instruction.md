When embedding the same table more than once in a single request—especially across different nesting levels and/or when computed relationships are involved—PostgREST generates invalid SQL due to alias collisions and incorrect references to the parent row value passed into computed-relationship functions.

Two classes of failures occur:

1) Embedding the same related table multiple times can produce SQL that reuses the same join/table name, resulting in PostgreSQL errors such as:

```
table name "<join_alias>" specified more than once
```

This happens even when the embeds refer to the same underlying table through different relationship paths. Users can sometimes work around it by manually aliasing one of the embeds in the `select=` tree, but PostgREST should generate correct SQL without requiring the user to add aliases just to avoid internal name collisions.

2) With deeply nested embeds that include the same table name at multiple levels, PostgREST can generate SQL that triggers PostgreSQL errors like:

```
aggregate functions are not allowed in FROM clause of their own query level
```

This again is caused by alias/name reuse in the generated lateral joins/subqueries.

Additionally, when a computed relationship is used and it returns rows of a table type, the SQL generation may incorrectly pass an identifier that is not in scope to the computed relationship function. For example, for a computed relationship like:

```sql
create or replace function api.root_container(api.container)
returns setof api.container
stable language sql
as $$
  select * from api.container limit 1
$$;
```

A request such as:

```
select=well_id,container(root_container(*))
```

can result in SQL that calls the computed relationship function with a non-existent reference:

```sql
FROM api.root_container("container")
```

which produces:

```
ERROR:  column "container" does not exist
```

Instead, the function argument must reference the correct row variable/alias for the parent table instance in scope (e.g. the alias of the `container` row selected in the outer lateral join), so the generated SQL uses that alias when invoking the computed relationship.

PostgREST should ensure that:
- Every embedded relation instance (including repeated embeddings of the same base table) gets a unique SQL alias at its query level so that no table/subquery name is specified more than once.
- Deeply nested embeddings that reuse the same table do not create alias collisions that lead to invalid correlated subqueries/lateral joins.
- Computed relationship SQL calls pass the correct parent-row identifier (the actual table alias in scope), not the JSON/embed name or an out-of-scope identifier.

After fixing this, users should be able to embed the same table multiple times across different nesting levels (with and without computed relationships) without adding manual aliases, and without hitting the PostgreSQL errors shown above.