When calling an RPC (table-valued function) endpoint that returns a set of rows, PostgREST incorrectly rejects filters applied to columns that are not part of the requested `select` projection.

Reproduction example:

```bash
curl 'http://localhost:3000/rpc/getallprojects?select=id,client_id&name=like.OSX'
```

Expected behavior: the request should succeed and return only rows matching the filter `name LIKE 'OSX'`, while the response body should include only the selected columns (`id`, `client_id`). Filtering should be allowed on any column produced by the table-valued function result type, even if that column is not included in `select`.

Actual behavior: PostgREST returns an error like:

```json
{"code":"42703","details":null,"hint":null,"message":"column projects.name does not exist"}
```

This indicates PostgREST is resolving filter fields only against the selected/projection columns (or otherwise losing access to non-selected columns) when building the query for table-valued function results.

Fix the RPC query building so that filters are resolved against the full set of columns available from the RPC’s returned composite/table type (or equivalent row source), not only against the columns listed in `select`. This should work for common filter operators (e.g., `eq`, `like`, etc.) and should not require adding filtered columns to `select`.

Ensure this works consistently for both GET-style RPC calls (query string parameters) and POST-style RPC calls (JSON body parameters), and does not break existing behavior for pagination/count headers on set-returning RPCs.