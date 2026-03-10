The generated OpenAPI specification served at the API root ("/") does not advertise that certain RPC endpoints can be called with HTTP GET, even though PostgREST actually allows calling some functions via GET (e.g., immutable or otherwise read-only functions that are safe to expose as GET). This causes Swagger UI / OpenAPI consumers to believe only POST is supported for RPC endpoints.

For example, if an instance exposes an RPC function at `/rpc/add_them`, calling `GET /rpc/add_them?a=1&b=2` works and returns `3`, but the OpenAPI JSON at `/` only lists a `post` operation under the `/rpc/add_them` path item and does not include a corresponding `get` operation. Similarly, for a SQL function like:

```sql
CREATE OR REPLACE FUNCTION public.whoami()
RETURNS name
LANGUAGE sql
IMMUTABLE STRICT
AS $$ select current_user $$;
```

the function can be invoked via `GET /rpc/whoami`, but the OpenAPI spec omits the `get` method for `/rpc/whoami`.

Update the OpenAPI generation so that function (RPC) path items include a `get` operation whenever the function is callable via GET in PostgREST. The `get` operation should be a proper OpenAPI operation object (not just an empty stub) and should be consistent with the existing `post` operation metadata, including summary/description, parameters (query parameters for function arguments for GET), and response schema/description as appropriate.

Expected behavior: fetching `GET /` (or requesting OpenAPI JSON via the appropriate Accept header) returns an OpenAPI document whose `paths` includes both `post` and `get` under `/rpc/<function_name>` when GET invocation is supported for that function.

Actual behavior: the OpenAPI document only includes `post` under `/rpc/<function_name>` and omits `get`, even though GET calls succeed at runtime.