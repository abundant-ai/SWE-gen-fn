When calling an RPC that returns a table type, PostgREST supports resource embedding (including computed relationships). However, embedding breaks when the computed relationship is implemented using overloaded PostgreSQL functions (same function name, different argument types), even though embedding works when querying the tables directly.

Example scenario:

- You have two table types, `api.test` and `api.test1`.
- You define two computed relationship functions with the same name but different argument types:

```sql
CREATE FUNCTION api.embed(api.test) RETURNS SETOF api.embedthis AS $$
  SELECT * FROM api.embedthis LIMIT 1;
$$ STABLE LANGUAGE sql;

CREATE FUNCTION api.embed(api.test1) RETURNS SETOF api.embedthis AS $$
  SELECT * FROM api.embedthis LIMIT 2;
$$ STABLE LANGUAGE sql;
```

- You define an RPC returning `SETOF api.test`:

```sql
CREATE FUNCTION api.myrpc() RETURNS SETOF api.test
LANGUAGE sql
AS $function$
  SELECT * FROM api.test;
$function$;
```

Expected behavior:
- A direct table request with embedding works:
  - `GET /test?select=*,embed(*)` returns rows with an `embed` array.
- A direct request to the other table also works:
  - `GET /test1?select=*,embed(*)` returns rows with an `embed` array.
- The RPC should also support embedding computed relationships the same way:
  - `GET /rpc/myrpc?select=*,embed(*)` should return `api.test` rows with an `embed` array computed via `api.embed(api.test)`.

Actual behavior:
- After introducing the overloaded `api.embed(api.test1)`, embedding on the RPC response fails, even though embedding on `/test` and `/test1` still works.
- The RPC request `GET /rpc/myrpc?select=*,embed(*)` errors with:

```json
{
  "code": "42725",
  "details": null,
  "hint": "Could not choose a best candidate function. You might need to add explicit type casts.",
  "message": "function api.embed(record) is not unique"
}
```

The bug is that PostgREST ends up trying to resolve the computed relationship function as if it were `api.embed(record)` (or otherwise too generically typed) when the embedding is applied to an RPC result, which becomes ambiguous once there are overloaded candidates. PostgREST should correctly resolve the computed relationship function based on the actual composite/table type returned by the RPC (e.g., `api.test`) so that overloads on other types do not cause ambiguity.

Fix this so that resource embedding for RPCs returning table types continues to work even when computed relationships are implemented using overloaded functions. This should handle both one-to-many and many-to-one computed relationship styles, including variants defined with `SETOF` and those returning a single row (e.g., via `ROWS 1` semantics), and it must not regress existing computed relationship embedding behavior on normal table endpoints.