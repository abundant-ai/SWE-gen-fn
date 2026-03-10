When using custom media type handlers, PostgREST incorrectly falls back to a JSON default in the “any” (catch-all) handler, which prevents certain valid vendor media types from being recognized/served unless they map cleanly to application/json. This shows up when a client sends an Accept header for a custom binary/document media type: even after creating the corresponding PostgreSQL domain (e.g. "application/vnd.openxmlformats-officedocument.wordprocessingml.document" as bytea) and defining the handler function as documented, requests still fail with HTTP 415.

Example failure:
A request with header `Accept: application/vnd.openxmlformats-officedocument.wordprocessingml.document` returns:

- Status: 415 Unsupported Media Type
- Body:
```json
{"code":"PGRST107","details":null,"hint":null,"message":"None of these media types are available: application/vnd.openxmlformats-officedocument.wordprocessingml.document"}
```

Expected behavior:
- If a PostgreSQL domain exists with the exact name of the requested media type and a corresponding media type handler is available, PostgREST should negotiate that media type and return a successful response.
- For generic/unknown “any” results (e.g., a handler that is intended to work for arbitrary media types), PostgREST must not default to `application/json`. Instead, it should use a generic binary default (`application/octet-stream`) so that non-JSON custom media types can be served without being rejected during media type negotiation.

Concretely, calling the query endpoint with `Accept: application/vnd.twkb` (or other non-JSON custom types) should return a 200 response with `Content-Type` matching the requested media type, and the response body should be the raw binary/text produced by the configured handler. Requests with an unsupported Accept (e.g. `text/plain` when no handler exists) should continue to return the same PGRST107 error and 415 status.

Fix the media type negotiation/handler selection logic so that the catch-all/any handler does not set `application/json` as a default content type, and custom vendor media types like `application/vnd.openxmlformats-officedocument.wordprocessingml.document` can be recognized when their domains/handlers are present.