Computed relationships behave incorrectly when the underlying computed function returns a table row type without using `SETOF`.

When defining a computed relationship via a SQL function that returns a table type (e.g. `returns api.films`) rather than `returns setof api.films`, PostgREST currently fails to treat the function as a proper many-to-one embedding. This leads to confusing/incorrect embedding behavior compared to the equivalent `SETOF ... ROWS 1` definition.

Reproduction scenario (conceptual):
- You have a “child” resource (e.g. `videogames`) and a “parent” resource (e.g. `designers`).
- A computed relationship function exists to fetch the parent from the child, but it is declared as a scalar rowtype return, like:

```sql
create function computed_designers_noset(videogames)
returns designers
stable language sql
as $$
  select * from designers where designers.name = $1.designer
$$;
```

Expected behavior:
- Embedding should work the same way as for a many-to-one computed relationship defined with `returns setof designers ... rows 1`.
- A request embedding the relationship should return a single embedded object per row, not an array and not duplicated base rows.

For example, calling:

```
GET /videogames?select=name,designer:computed_designers_noset(name)
```

should return JSON shaped like:

```json
[
  {"name":"Civilization I","designer":{"name":"Sid Meier"}},
  {"name":"Civilization II","designer":{"name":"Sid Meier"}},
  {"name":"Final Fantasy I","designer":{"name":"Hironobu Sakaguchi"}},
  {"name":"Final Fantasy II","designer":{"name":"Hironobu Sakaguchi"}}
]
```

Additionally, this scalar-return computed relationship must behave correctly with:
- `!inner` joins on the embedded relationship
- filtering on embedded fields (e.g. `designer.name=like.*Hironobu*`)
- `Prefer: count=exact` producing correct `Content-Range` totals

Actual behavior (bug):
- PostgREST does not “just work” for this non-`SETOF` computed relationship: it misclassifies or mishandles the relationship cardinality/embedding, leading to incorrect embedding semantics compared to the `SETOF` variant.

Fix required:
- Ensure computed relationships whose functions return a table row type (non-`SETOF`) are correctly supported for embedding as a many-to-one relationship.
- The embedding output, join behavior (`!inner`), filtering, and counting must match the behavior of the equivalent computed relationship defined as `SETOF` with an appropriate `ROWS 1` estimation.