RPC calls fail for PostgreSQL functions whose declared return type is `record` or `setof record`. In PostgREST v11.0.0, calling an RPC endpoint for such a function triggers a PostgreSQL error instead of returning JSON rows.

Example function:

```sql
create or replace function setof_record() returns setof record as $$
  select * from projects;
$$ language sql;
```

When requesting the RPC endpoint:

```sh
curl localhost:3000/rpc/setof_record
```

PostgREST currently returns an error response like:

```json
{"code":"42601","details":null,"hint":null,"message":"a column definition list is required for functions returning \"record\""}
```

Expected behavior: the RPC should succeed and return a JSON array of rows (as it did previously), i.e. the function should be invoked in a way that does not require a column definition list for `record`/`setof record`.

Additionally, when invoking an RPC function that returns `setof record`, PostgREST should treat it as a scalar-style RPC result (so that the call works without requiring the client to provide a record definition). A known limitation of this behavior is that column projection on the returned record is not supported: a request like

```sh
curl 'localhost:3000/rpc/setof_record?select=id'
```

should fail with an undefined-column style error (for example `42703` with a message indicating `setof_record.id` does not exist), rather than pretending that record fields can be selected.

Fix the regression so that RPC endpoints for functions returning `record` or `setof record` no longer error with `42601` and instead return results successfully, while preserving the limitation that field-level `select=` projection is not available for these record-returning RPCs.