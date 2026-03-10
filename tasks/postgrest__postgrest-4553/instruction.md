When PostgREST resolves an RPC call, it has a fallback that treats a request body as a single unnamed JSON/JSONB argument if the target function appears to have exactly one JSON/JSONB parameter. Currently, this fallback can incorrectly match functions whose single JSON/JSONB parameter is *named* (e.g., `data json`), because the matching logic only checks the parameter type and not whether the parameter actually has no name.

Reproduction example:

```sql
create or replace function test.named_json_param(data json) returns json as $$
  select data;
$$ language sql;
```

Calling the function via RPC with a JSON object body like:

```http
POST /rpc/named_json_param
Content-Type: application/json

{"A": 1, "B": 2, "C": 3}
```

Expected behavior: PostgREST should *not* consider this function a candidate for the “single unnamed json/jsonb parameter” fallback, because the function’s only parameter is named (`data`). The request should fail with the schema-cache function lookup error that includes the attempted named-parameter signature, e.g.:

```json
{
  "code": "PGRST202",
  "message": "Could not find the function test.named_json_param(A, B, C) in the schema cache",
  "details": "Searched for the function test.named_json_param with parameters A, B, C or with a single unnamed json/jsonb parameter, but no matches were found in the schema cache.",
  "hint": null
}
```

Actual behavior: The function can be incorrectly treated as matching the single-parameter JSON fallback and the error becomes less precise, returning a PostgreSQL error like:

```json
{
  "code": "42883",
  "message": "function test.named_json_param() does not exist",
  "details": null,
  "hint": "No function matches the given name and argument types..."
}
```

Fix the RPC function-parameter matching so that the “has single unnamed parameter” check (commonly implemented as `hasSingleUnnamedParam`) only returns true when the single parameter is both of type JSON/JSONB *and* has no name (its name is empty). Functions with a single named JSON/JSONB parameter must not match this fallback, and the resulting error response for the scenario above must use the PostgREST schema-cache lookup error (`PGRST202`) rather than the PostgreSQL “function does not exist” error (`42883`).