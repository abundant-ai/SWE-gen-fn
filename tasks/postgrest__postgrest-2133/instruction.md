PostgREST currently mishandles filters that are intended to apply to embedded resources. In some cases, an embedded filter is silently ignored when the embedded resource name in the filter key does not match any embedded relationship selected in the request. This can happen due to a typo or because the client references a resource that isn’t actually embedded in the `select` clause.

For example, embedded resources can be filtered using query parameters prefixed with the embedded resource name:

```
GET /films?select=*,roles(*)&roles.character=in.(Chico,Harpo,Groucho)
```

This should filter the embedded `roles` by `character`.

However, if the client provides an invalid embedded resource prefix, PostgREST currently ignores the filter and behaves as if no embedded filter was provided, returning unfiltered embedded data:

```
GET /films?select=*,roles(*)&resource_not_exist.character=in.(Chico,Harpo,Groucho)
```

Expected behavior: the request should fail with an HTTP 400 error indicating that the embedded resource referenced in the filter does not exist (or is not part of the embedded resources selected by `select`). The error response should clearly identify the unknown embedded resource name so that users can correct typos (for example: a message like `resource resource_not_exist does not exist`).

Actual behavior: the request succeeds and returns data as if the filter was not present.

Implement validation so that when parsing and applying filters, any filter key using the embedded-resource prefix form (`<embed>.<field>=...`) must correspond to a real embedded relationship in the request. If it does not, PostgREST must not ignore it; it must return a 400 error instead.

Additionally, embedding with top-level filtering via an inner join should allow empty parentheses in the embedded selection without causing misleading errors. For example, this query is intended to inner-join `film_category` only for filtering (return only films that have at least one category) while not embedding any `film_category` fields:

```
GET /film?select=*,film_category!inner()
```

Expected behavior: this should be treated as a valid embedded selection with an inner join used for filtering, and it should not error simply because no columns were requested inside the parentheses.

Actual behavior: it can result in an error like `column film.film_category does not exist` (or otherwise fail due to mis-parsing the empty embedded selection).

Fix both issues so that (1) unknown embedded filter prefixes produce a 400 error instead of being ignored, and (2) empty embedded selections like `film_category!inner()` are accepted and correctly interpreted as “use the relationship for join/filtering but don’t embed fields.”