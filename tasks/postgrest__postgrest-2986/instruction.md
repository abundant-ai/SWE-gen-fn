PostgREST currently always returns `Access-Control-Allow-Origin: *`, which makes it impossible to restrict or disable CORS at the application level (e.g., when running behind an ingress/proxy that should control CORS). Additionally, `OPTIONS` handling for CORS preflight requests is inconsistent: successful preflights are effectively handled by the CORS middleware, but failing preflights (for example when `Access-Control-Request-Method` is not allowed) fall through to PostgREST’s own `OPTIONS` response and do not include the required preflight headers (notably `Access-Control-Allow-Methods`), causing browsers to reject the preflight.

Add a new configuration setting named `server-cors-allowed-origins` that allows specifying which origins are allowed for CORS.

Behavior required:

- When `server-cors-allowed-origins` is unset or empty, CORS should behave as before (responses include `Access-Control-Allow-Origin: *`).

- When `server-cors-allowed-origins` is set to one or more origins (e.g. `http://example.com`), PostgREST must not always send `Access-Control-Allow-Origin: *`. Instead, for requests that include an `Origin` header:
  - If the origin matches one of the configured allowed origins, respond with `Access-Control-Allow-Origin` set to that origin.
  - If the origin is not allowed, the request must not be treated as CORS-allowed. In particular, CORS preflight requests must not succeed in a way that browsers accept.

- `OPTIONS` requests that are CORS preflight requests (e.g. include `Origin` and `Access-Control-Request-Method`, and optionally `Access-Control-Request-Headers`) must be handled correctly both on success and failure:
  - On success, the response must include the standard preflight response headers such as `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods`, and `Access-Control-Allow-Headers` (as applicable).
  - On failure (e.g. `Access-Control-Request-Method: TRACE`), the response must not be a misleading `200 OK` without CORS preflight headers. It should return an error response appropriate for an invalid preflight, rather than falling back to a generic `Allow: ...` header that browsers ignore for CORS.

Reproduction example showing the current problematic behavior:

1) Valid preflight currently returns CORS headers (via middleware):
```bash
curl -X OPTIONS "http://localhost:3000/projects" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -H "Origin: http://localhost" -i
```
Expected: a valid preflight response with `Access-Control-Allow-Origin` reflecting the configured origin policy, and `Access-Control-Allow-Methods` including `POST`.

2) Invalid preflight currently returns `200 OK` with only `Access-Control-Allow-Origin: *` and `Allow: ...`, missing `Access-Control-Allow-Methods`, so browsers fail the preflight:
```bash
curl -X OPTIONS "http://localhost:3000/projects" \
  -H "Access-Control-Request-Method: TRACE" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -H "Origin: http://localhost" -i
```
Expected: an error response for the invalid preflight (rather than a successful 200), and it must not present as an allowed CORS preflight.

Also ensure the new `server-cors-allowed-origins` setting is reflected in PostgREST’s configuration output/normalization behavior (e.g., it should appear as a config key and accept values like `""` for empty and a concrete origin like `"http://example.com"`).