When requesting an exact total count (via `Prefer: count=exact`) on a top-level resource that includes embedded resources, the `Content-Range` total can become incorrect if an embedded relationship uses `!inner` and the `select=` list contains multiple embedded resources. The bug is order-dependent: changing the order of items inside the `select=` query parameter can change the reported total count even though the returned rows are identical.

For example, a request like:

```http
HEAD /film?select=*,film_category!inner(*),film_actor(*)
Prefer: count=exact
```

returns a correct `Content-Range` total (e.g. `0-63/64`). But reordering the embedded resources:

```http
HEAD /film?select=*,film_actor(*),film_category!inner(*)
Prefer: count=exact
```

can incorrectly return a much larger total (e.g. `0-63/1000`) even though the response body for the equivalent `GET` still contains the same 64 rows.

This also affects other schemas where an inner-joined embedded relationship is used to filter out rows with missing relationships. In particular, `!inner` embeddings are supposed to exclude rows where the relationship is null, and the exact count should reflect that exclusion regardless of `select=` ordering.

Fix the query planning/building so that the top-level count used for `Content-Range` is computed consistently and does not depend on the order of embedded resources in `select=`. After the fix, any permutation of the `select=` items must yield the same total count, and the total must match the number of top-level rows that would be returned without pagination.

The following behaviors must hold:

- For many-to-one embeddings, `!inner` excludes rows with null related records, and the exact count reflects only the remaining rows.
- When filtering on an embedded resource (e.g. `&clients.id=eq.1` alongside `select=...,clients!inner(...)`), both the returned rows and the exact count reflect the filter.
- When filtering on a nested embedded resource (e.g. two levels deep like `projects.clients.id=eq.1` with `select=...,projects!inner(...,clients!inner(...))`), the exact count is correct and remains correct regardless of the order of embeddings inside `select=`.