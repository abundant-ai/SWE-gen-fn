PostgREST should support propagating an incoming HTTP request “trace/request id” header back in the HTTP response, controlled by a new configuration option named `server-trace-header`.

Currently, there is no reliable way to correlate a client request with the response (and indirectly with downstream database activity) using a user-chosen header such as `X-Request-Id`, `CF-Ray`, or `traceparent`. Users want to set a header name once in configuration and have PostgREST echo that header (if present on the request) on every response so that intermediaries and clients can trace requests end-to-end.

Implement the following behavior:

When `server-trace-header` is configured to a non-empty header name (for example `X-Request-Id`), then for any HTTP request that includes that header, PostgREST must include the same header with the exact same value on the HTTP response. This must work consistently across different endpoints, including the API root (`/`), table/resources (e.g. `/projects`), and RPC calls (e.g. `/rpc/add_them?a=2&b=4`).

When `server-trace-header` is an empty string (the default), PostgREST should not add any trace header to responses.

The configuration must be recognized in the normal configuration system (config file and environment variable forms) and must round-trip correctly when PostgREST outputs/prints its effective configuration (i.e., it should appear as `server-trace-header = ""` by default and as the configured header name when set).

Example expected behavior (with `server-trace-header = "X-Request-Id"`):
- Request: `HEAD /` with header `X-Request-Id: 1` -> Response includes `X-Request-Id: 1`
- Request: `HEAD /projects` with header `X-Request-Id: 2` -> Response includes `X-Request-Id: 2`
- Request: `HEAD /rpc/add_them?a=2&b=4` with header `X-Request-Id: 3` -> Response includes `X-Request-Id: 3`

The header name matching should behave like standard HTTP header handling in PostgREST (i.e., it should successfully find the header even if the incoming request uses a different casing), and the response should use the configured header name as the header key.