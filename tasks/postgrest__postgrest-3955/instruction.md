HEAD requests (and other responses where the body might be omitted) can hide useful error details in PostgREST. For example, a GET that hits a database statement timeout returns a JSON error body like {"code":"57014","details":null,"hint":null,"message":"canceling statement due to statement timeout"}, but the equivalent HEAD request may only show a generic HTTP status (e.g., 500) with no error payload, making it hard to debug.

PostgREST should include a Proxy-Status HTTP response header (per RFC 9209) on error responses so clients can reliably read an error identifier even when the response body is not present. The header value must identify PostgREST and include the PostgREST/SQLSTATE error code as the error parameter.

When an error response is produced (including but not limited to request parsing/validation errors, schema cache errors, JWT/auth errors, and database-raised SQLSTATE errors), the response must include:

Proxy-Status: PostgREST; error=<ERROR_CODE>

Where <ERROR_CODE> is the same code that appears in the JSON error body (e.g., PGRST125 for an invalid path, PGRST205 for missing relation in schema cache, PGRST301 for malformed JWT, or a custom SQLSTATE like PT402 or 123). The presence of this header must not change the HTTP status code selection logic; it only adds a machine-readable error identifier to the headers.

Concrete expected behaviors:
- Requesting an invalid nested path should return HTTP 404 with error code PGRST125 and include Proxy-Status: PostgREST; error=PGRST125.
- Requesting a non-existent table should return HTTP 404 with error code PGRST205 and include Proxy-Status: PostgREST; error=PGRST205.
- Supplying an invalid JWT (e.g., wrong format) should return HTTP 401 with error code PGRST301 and include Proxy-Status: PostgREST; error=PGRST301.
- Calling an RPC that raises a custom SQLSTATE like PT402 should return HTTP 402 with code PT402 and include Proxy-Status: PostgREST; error=PT402.
- Calling an RPC that raises a custom SQLSTATE like 123 should return the mapped HTTP status (e.g., 332 in this scenario) with code 123 and include Proxy-Status: PostgREST; error=123.

The goal is that clients can always read Proxy-Status to know the specific PostgREST error code, even when they used HEAD or otherwise did not receive/parse a JSON body.