Arrow filtering (-> / ->>) on fields returned from RPC calls is broken when the RPC returns a TABLE that includes a composite-typed column, or returns SETOF a composite type directly. This is a regression introduced in PostgREST 11.2.0: the same request works in 11.1.0 but fails in 11.2.0.

Reproduction schema:

```sql
create type type_x as (
  id int,
  val text
);

create or replace function test.returns_type()
returns table(id int, val type_x) as $$
  select 1, row(1, 'value')::type_x ;
$$ language sql;
```

When making this request:

```bash
curl "http://localhost:3000/rpc/returns_type?val->>id=eq.1"
```

Expected behavior: the request succeeds and filters by the composite field’s subfield, returning the matching row, e.g.

```json
[{"id":1,"val":{"id":1,"val":"value"}}]
```

Actual behavior in 11.2.0: the request fails with a PostgreSQL undefined operator error because the generated SQL applies the JSON text operator directly to the composite type:

```json
{
  "code":"42883",
  "details":null,
  "hint":"No operator matches the given name and argument types. You might need to add explicit type casts.",
  "message":"operator does not exist: type_x ->> unknown"
}
```

PostgREST should correctly support json/jsonb arrow operators in both selection and filtering when the target expression is a composite value coming from an RPC result. In this case, `val->>id` must be interpreted in a way that works for composite types returned from functions (e.g., by converting the composite to a JSON-compatible representation before applying `->>`), so that arrow filtering works consistently across PostgREST 11.1.0 and 11.2.0.

This must work for:
- RPC functions that `RETURNS TABLE(...)` where one of the columns is a composite type and the client filters using `composite_column->subfield` or `composite_column->>subfield`.
- RPC functions that `RETURNS SETOF some_composite_type` and the client uses arrow filtering on the returned composite value.

The fix should ensure these requests no longer produce `42883 operator does not exist: <composite> ->> ...` and instead return the correctly filtered results.