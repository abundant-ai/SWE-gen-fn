PostgREST currently does not support ordering a top-level resource by a column (or expression) that belongs to a related resource included via embedding/relationship selection. Users want to request an embedded related object and then sort the parent rows using fields from that related object, using a syntax like `order=related_table(column).asc` (including nulls ordering), but this either fails to parse, is rejected as an invalid order term, or does not affect the result ordering.

Add support for “related orders” so that a request can order a resource by columns/expressions from a related resource for many-to-one and one-to-one relationships (including aliases used in `select=`). For example, given projects with an optional many-to-one relationship to clients, the following must work:

```http
GET /projects?select=id,clients(name)&order=clients(name).nullsfirst
```

Expected behavior: projects are sorted by `clients.name` with `NULL` client rows first, producing an order where rows with no client appear before Apple and Microsoft (and Apple rows before Microsoft).

Aliasing a relationship in the select must also be usable in `order=`:

```http
GET /projects?select=id,client:clients(name)&order=client(name).asc
```

Expected behavior: projects are sorted by `client.name` ascending, and rows with `NULL` client appear last by default.

Related ordering must also work when the relationship is a computed relationship (i.e., a to-one computed relationship exposed for embedding). Example:

```http
GET /videogames?select=id,computed_designers(id)&order=computed_designers(id).desc
```

Expected behavior: videogames are ordered by the embedded computed designer `id` descending.

Ordering by related fields must support ordering by expressions, including JSON operators on a related row for one-to-one relationships. Example:

```http
GET /trash?select=id,trash_details(id,jsonb_col)&order=trash_details(jsonb_col->key).asc
```

and

```http
GET /trash?select=id,trash_details(id,jsonb_col)&order=trash_details(jsonb_col->key).desc
```

Expected behavior: trash rows are ordered by the related `trash_details.jsonb_col->key` value ascending/descending respectively.

Finally, ordering must work for embedded resources (ordering within an embedded array) where the order term references a related resource inside that embedding. For example, a user embedding tasks (array) that each embed a project (to-one) should be able to order the tasks by a project column using the embedded-order syntax:

```http
GET /users?select=name,tasks(id,name,projects(id,name))&tasks.order=projects(id).desc&limit=1
```

Expected behavior: the returned user’s `tasks` array is sorted by `projects.id` descending.

The implementation should accept standard order modifiers (`asc`, `desc`, `nullsfirst`, `nullslast`) in combination with related-order terms, and must generate correct ordering even when the related resource is `NULL` (e.g., left-join semantics for optional relationships).