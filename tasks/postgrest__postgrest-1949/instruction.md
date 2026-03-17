When using resource embedding, filters that target an embedded resource (e.g., `clients.id=eq.2`) currently only affect the embedded JSON field, but do not restrict which top-level rows are returned. This makes it impossible to express queries like “return only projects that have an embedded client matching this filter” without workarounds.

For example, requesting projects with an embedded client and filtering by the embedded client id:

```http
GET /projects?select=id,clients(id)&clients.id=eq.2
```

Currently returns projects that do not match the embedded filter, with the embed coming back as `null` for non-matching rows (left-join behavior):

```json
[
  {"id":1,"clients":null},
  {"id":2,"clients":null},
  {"id":3,"clients":{"id":2}},
  {"id":4,"clients":{"id":2}},
  {"id":5,"clients":null}
]
```

Expected behavior: there must be a way to make embedded filters restrict the top-level resource, so that only top-level rows with at least one matching embedded row are returned (inner-join semantics for the embed). The API should support an explicit syntax on the embedded relationship to request this behavior.

For the same example, the request:

```http
GET /projects?select=id,clients!inner(id)&clients.id=eq.2
```

should return only projects that have a matching client:

```json
[
  {"id":3,"client":{"id":2}},
  {"id":4,"client":{"id":2}}
]
```

This top-level filtering must work for embedded relationships across common cardinalities, including many-to-one, one-to-many, and many-to-many. It must also work when the embedded resource is a view (not only a base table), i.e., using `!inner` should still correctly filter the top-level resource when the embedded target is a view.

The default behavior must remain unchanged: without `!inner`, embedding should continue to behave like a left join where non-matching embedded rows result in `null`/empty embedded values but do not exclude the top-level rows.

If a server configuration option for choosing a default embed join mode exists (e.g., setting a default of `inner`), it must be parsed and reflected correctly in runtime behavior and in configuration output; overriding per request with `!left`/`!inner` should behave consistently with the selected default.