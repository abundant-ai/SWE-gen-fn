Filtering using JSON/JSONB arrow operators (-> and ->>) currently generates SQL that prevents PostgreSQL from using expression indexes, and in some cases generates invalid SQL when the filtered column is a composite type returned from an RPC.

1) JSONB index not used due to unnecessary to_jsonb()
When a table has a jsonb column with an expression index like:

```sql
create index bets_contract_id on bets ((data->>'contractId'));
```

A direct SQL query can use the index:

```sql
select id from bets where data->>'contractId' = 'foo' limit 1;
```

But when performing the equivalent filter via the HTTP API, e.g.:

`/bets?select=id&data->>contractId=eq.foo`

PostgREST generates a WHERE clause that wraps the column with `to_jsonb(...)`, producing something like:

```sql
... WHERE to_jsonb(bets.data)->>$1 = $2
```

This prevents PostgreSQL from using the existing expression index on `(data->>'contractId')`, resulting in a sequential scan instead of an index scan. The generated SQL for arrow filtering should not apply `to_jsonb()` to columns that are already `jsonb` (and likewise should avoid transformations that change the indexed expression), so that queries like `col->>'key' = 'value'` can match expression indexes and use them.

Expected behavior: For jsonb columns, filtering with `col->>'key'` (and similar arrow operator chains) should produce SQL equivalent to `col->>'key' = ...` without wrapping the base column in `to_jsonb`, allowing PostgreSQL to use expression indexes.

Actual behavior: The filter expression uses `to_jsonb(col)` leading to plans dominated by sequential scans even when an appropriate expression index exists.

2) Regression: arrow filtering on composite columns returned by RPC
When calling an RPC function that `RETURNS TABLE` with a column whose type is a composite type (or returns `SETOF <composite_type>`), filtering on a composite-typed column using arrow operators is currently broken.

Given a composite type and function:

```sql
create type type_x as (id int, val text);

create or replace function returns_type()
returns table(id int, val type_x) as $$
  select 1, row(1, 'value')::type_x ;
$$ language sql;
```

A request like:

`/rpc/returns_type?val->>id=eq.1`

currently fails with:

```json
{
  "code":"42883",
  "message":"operator does not exist: type_x ->> unknown",
  "hint":"No operator matches the given name and argument types. You might need to add explicit type casts."
}
```

Expected behavior: Arrow filtering should work against composite-typed columns returned from RPC calls by applying the arrow extraction to a JSON/JSONB representation (or otherwise producing a valid SQL expression), and the request above should succeed returning the matching row(s), e.g. `[{"id":1,"val":{"id":1,"val":"value"}}]`.

Actual behavior: The generated SQL applies `->>` directly to the composite type, which PostgreSQL does not support, causing error 42883.

The fix should ensure:
- JSON/JSONB arrow filtering does not introduce unnecessary conversions that break index usage.
- Arrow filtering on composite-typed columns returned from RPC functions produces valid SQL and no longer errors with `operator does not exist: <composite> ->> unknown`.
- Existing behavior for selecting/shaping JSON subfields (including casts such as `settings->>foo::json` and nested arrow chains) continues to work, and malformed casts still return the appropriate 400 error with PostgreSQL’s message.