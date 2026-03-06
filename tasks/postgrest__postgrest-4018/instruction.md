PostgREST responses currently do not include the standard HTTP `Content-Length` header for many responses with bodies (notably JSON error responses and some metadata responses). This makes it difficult for operators and proxies to observe response sizes, since upstream proxies (e.g., Nginx) typically won’t buffer and compute `Content-Length` themselves.

Implement support for automatically setting `Content-Length` on responses where PostgREST knows the full response body size.

Behavior required:
- For responses that include a non-empty body (including JSON error payloads), the server must add a `Content-Length` header whose value equals the exact byte length of the response body as sent on the wire.
- The header value must be correct for UTF-8 encoded response bodies (i.e., computed in bytes, not characters).
- Examples of responses that must include `Content-Length`:
  - A 404 response to a request with `Accept: application/openapi+json` when the root endpoint metadata is disabled must include `Content-Length: 93` along with the JSON error body `{"code":"PGRST126","details":null,"hint":null,"message":"Root endpoint metadata is disabled"}`.
  - A 500 response for a PostgreSQL error like `stack depth limit exceeded` must include `Content-Length: 217` along with the JSON error body.
  - A 404 response for an invalid nested path error must include `Proxy-Status: PostgREST; error=PGRST125` and also include `Content-Length: 96` for its JSON error body.
  - Other structured error responses (404, 401, 402, etc.) must similarly include an accurate `Content-Length`.

Cases where `Content-Length` must be absent:
- `HEAD` requests must not include `Content-Length` even when the corresponding `GET` would return a body (for example, a `HEAD /` request accepting `application/openapi+json` should return status 200 with a `Content-Type: application/openapi+json; charset=utf-8` header and must not include `Content-Length`).
- Responses with no body (notably `204 No Content` from methods like `PATCH`, `PUT`, `DELETE` that return an empty response) must not include `Content-Length`.

The implementation should ensure the header is consistently applied across different response types (success and error), without breaking existing header behavior such as custom headers set via server features (e.g., `X-Custom-Header`) or overridden `Content-Type` behavior.