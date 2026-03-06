Some request paths currently return an HTTP error status with an empty/blank JSON error body because they use a generic `NotFound` error that does not populate the standard error payload.

This is user-visible in at least two scenarios:

1) When OpenAPI/metadata at the root endpoint is disabled and the client requests OpenAPI output via the `Accept: application/openapi+json` header, the server should respond with HTTP 404 and a JSON error object. Currently, the response status may be 404 but the error JSON is empty or missing meaningful fields.

Expected response for a GET request to `/` with header `Accept: application/openapi+json` when OpenAPI is disabled:

```json
{"code":"PGRST126","details":null,"hint":null,"message":"Root endpoint metadata is disabled"}
```

The HTTP status must be 404.

2) When a client requests a resource path that is invalid (for example, a table/resource that does not exist), the server should return a structured JSON error instead of an empty `NotFound` payload. For a nonexistent table request like `GET /faketable`, the error should be a 404 with a JSON body that includes code/message and, when available, a hint pointing to a similarly-named existing table.

Expected response for `GET /faketable`:

```json
{
  "code":"PGRST205",
  "details":null,
  "hint":"Perhaps you meant the table 'test.private_table'",
  "message":"Could not find the table 'test.faketable' in the schema cache"
}
```

The fix should remove usage of the empty `NotFound` error in these code paths and introduce dedicated error cases so that error responses consistently include `code`, `message`, `details`, and `hint` fields (using `null` when not applicable), while preserving the correct HTTP status codes.