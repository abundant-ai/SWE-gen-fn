When using PostgREST resource embedding with an explicit join type (e.g. `!inner`) it should be possible to specify an empty embedded selection `relation!inner()` to use the relationship only for filtering/join semantics without returning any embedded JSON object/array in the response.

Currently, requests like:

```http
GET /film?select=*,film_category!inner()
```

fail with an error similar to:

```
column film.film_category does not exist
```

This is misleading because `film_category` is a valid relationship, and the request is semantically valid: the user wants to restrict the top-level rows to those having a matching related row (inner join behavior), but does not want any embedded related data included in the returned JSON.

The API should accept empty parentheses in embed selections and treat it as “embed nothing but keep the relationship join for filtering.” For example, this request should succeed and return only the selected top-level fields, while still applying the inner-join restriction and any filters on the related resource:

```http
GET /clients?select=id,name,projects!inner()&projects.name=eq.IOS
```

Expected response shape (example):

```json
[{"id":2,"name":"Apple"}]
```

with no `projects` key in the returned objects.

In addition, requesting a resource with an explicitly empty select should behave the same as omitting `select` entirely for that resource. In particular:

```http
GET /projects
```

and

```http
GET /projects?select=
```

should produce the same result.

Implement support for parsing and planning empty embedded selections so that:
- `relation!inner()` (and similar embed syntax) is accepted.
- Related-table filters like `relation.column=eq.value` still work when the embedded selection is empty.
- The response does not include the embedded relation key when nothing is selected from it.
- Error handling is corrected so valid empty embed syntax does not produce “column does not exist” errors.