PostgREST’s request log currently does not include the “current user” associated with a request (the role actually used for the DB session). This makes it difficult to audit traffic when many requests are made under different authenticated roles.

When PostgREST handles a request, it determines an effective database role (for example the anonymous role when no JWT is provided, or an author role when a JWT with the appropriate role claim is provided). The request logging output should include this resolved role as an explicit field in each request log line.

Expected behavior:
- For a request that runs as the anonymous role (e.g., no JWT / unauthenticated request), the request log entry should include the anonymous role name.
- For a request that runs as an authenticated role (e.g., JWT-present request that resolves to an author role), the request log entry should include that authenticated role name.
- The value logged must reflect the actual role used for the request/DB transaction (the same one that would control permissions), not merely a raw claim value when role switching/fallback logic applies.
- This should work consistently across endpoints, including successful requests and permission-rejected requests (so that denied access is still attributable to the role that was attempted).

Actual behavior:
- Request log entries omit the current user/role entirely, so two requests with different effective roles produce indistinguishable log lines aside from request path/method/status.

Implement the change so that request logging always records the current request’s effective role (current user) in the log output, in a stable format consistent with existing request log formatting.