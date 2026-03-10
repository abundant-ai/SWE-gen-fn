Filtering on embedded (related) resources is currently too restrictive and prevents several common query patterns involving LEFT JOIN semantics and conditions across relationships.

When a client embeds a related resource via `select=...related(...)`, filters that target the embedded resource should allow explicit null checks (`is.null`, `not.is.null`) and behave consistently with LEFT JOIN behavior so that anti-join style queries are possible.

A common failing scenario is trying to fetch rows whose related rows do not exist (ANTI JOIN using a LEFT join). For example, embedding a relationship and filtering it as null should return only the “orphans”:

```
GET /projects?select=name,clients()&clients=is.null
```

Expected behavior: return only projects that have no related `clients` row.
Actual behavior: the API cannot express this correctly (either rejects the operator on the embedded resource or does not filter as expected), making it impossible to replicate SQL patterns like `... LEFT JOIN ... WHERE related.id IS NULL`.

Similarly, clients need a more flexible replacement for `!inner` when they want to require presence of a related row while still filtering on that related table. A query like the following should work and produce the same result set as doing an inner join embed:

```
GET /projects?select=name,clients(*)&clients.id=eq.1&clients=not.is.null
```

Expected behavior: return only projects whose embedded `clients` exists and matches `clients.id=eq.1`.

Additionally, boolean logic across related tables should be supported so clients can express “match if either relationship condition is satisfied”. For example, when embedding multiple relationships and applying filters to each, `or=(...)` should be able to reference related-table predicates using null checks on those relationships:

```
GET /client?select=*,clientinfo(),contact()&clientinfo.other=ilike.*main*&contact.name=ilike.*tabby*&or=(clientinfo.not.is.null,contact.not.is.null)
```

Expected behavior: return clients where either a matching `clientinfo` row exists or a matching `contact` row exists (or both).

Finally, filtering using operators other than `is null` / `not is null` on embedded resources should continue to be rejected with a clear error, but null-check operators must be allowed. Users currently encounter an error like:

```
{"code":"PGRST120","details":"Only is null or not is null filters are allowed on embedded resources","message":"Bad operator on the 'inbox_id' embedded resource"}
```

The implementation should ensure that null filters on embedded resources are accepted and correctly applied (enabling LEFT anti-join and presence checks), and that `or` expressions can combine conditions that refer to related resources using these null checks.