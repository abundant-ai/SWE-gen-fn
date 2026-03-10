When a database function used as a pre-request procedure (or any RPC) raises an exception, PostgREST currently allows controlling the HTTP status code via the SQLSTATE mapping and provides error details in the usual error JSON, but it does not allow full control of the HTTP response body and response headers. In particular, any configuration changes made before raising (e.g., via `set_config`) are not persisted into the error response, so it’s impossible to implement flows like an HTTP 302 redirect with a `Location` header or to return a custom JSON body alongside custom headers.

Update PostgREST so that raising an exception with a dedicated/custom SQLSTATE (as discussed in issue #2492) can fully define the HTTP response returned by PostgREST:

- The exception’s `message` field must be treated as a JSON value representing the response body to send back verbatim (rather than PostgREST’s default error object).
- The exception’s `detail` field must be treated as a JSON value representing a list of HTTP headers to include in the response.
- The HTTP status code must still be derived from the SQLSTATE mapping for that exception.

This should enable scenarios like returning a 302 response from a pre-request procedure, including a `Location` header and a custom body, even though an exception was raised.

If `message` or `detail` cannot be parsed as the expected JSON, PostgREST should fall back to the normal error response format (and not crash). Header handling must support multiple headers and preserve exact header names/values as provided. The resulting response should include the custom headers in addition to any normal headers PostgREST would include for that response (unless they conflict, in which case the custom header value should take precedence).