GET requests to RPC functions with no parameters incorrectly return a 404 “Not Found” when the request includes certain `Content-Type` headers such as `text/plain` or `application/octet-stream`, even though the function exists and can be called successfully without that header.

Reproduction:
1) Create a no-parameter function, for example:
```sql
create function api.noparam() returns integer
  immutable
  language sql
as $$
select 1;
$$;
```
2) Call it via RPC:
- `curl "http://localhost:3000/rpc/noparam"` returns `1` as expected.
- `curl "http://localhost:3000/rpc/noparam" -H "Content-Type: text/plain"` currently returns:
```json
{
  "hint":"If a new function was created in the database with this name and parameters, try reloading the schema cache.",
  "message":"Could not find the api.noparam() function in the schema cache"
}
```

Expected behavior: For GET (and similarly HEAD, if applicable) requests to `/rpc/<function>` that have no parameters, the server should correctly resolve and execute the no-argument function even if a `Content-Type` header like `text/plain` or `application/octet-stream` is present. The presence of these `Content-Type` headers must not cause the request to be interpreted as having a body that changes how RPC function-parameter resolution works.

Actual behavior: When `Content-Type` is set to `text/plain` or `application/octet-stream` on a GET request to an RPC endpoint for a no-parameter function, the request is mis-routed/mis-planned such that the function lookup fails and a 404 is returned claiming the function is missing from the schema cache.

Fix the request parsing/routing so that GET requests to RPC endpoints do not treat these `Content-Type` values as implying a body-based RPC call, and instead correctly call the existing no-parameter function.