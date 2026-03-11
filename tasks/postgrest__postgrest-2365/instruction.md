PostgREST currently opens a database transaction even when an HTTP request is rejected before it could possibly run a query. This happens for (1) URLs that don’t map to a valid API target (e.g. requesting nested routes that don’t exist) and (2) unsupported HTTP methods. As a result, the server acquires a DB connection, runs session GUC setup (e.g. setting request.method, request.path, headers/cookies), and issues a BEGIN/COMMIT pair even though the request should fail purely at the HTTP layer.

Reproduction examples:
- Requesting a non-existent nested route like GET /projects/nested (or deeper paths like /projects/nested/double) should return 404 without touching the database.
- Sending an unsupported HTTP method should return a 405 JSON error without touching the database. For example, sending CONNECT / or TRACE / (or any other non-supported method such as OTHER) must return status 405 with a JSON body like:

  {"hint":null,"details":null,"code":"PGRST117","message":"Unsupported HTTP method: CONNECT"}

  (with the method name reflected in the message for TRACE/OTHER, etc.).

Additionally, when OpenAPI is disabled, a request like GET / with Accept: application/openapi+json should return 404.

Expected behavior: requests that are rejected due to an invalid URL/target or unsupported HTTP method must be handled at the request parsing/routing layer (e.g., during API request construction) and must not acquire a database connection, must not start any transaction, and must not run any per-request DB setup.

Actual behavior: these error cases still cause an empty transaction (BEGIN + session setup + COMMIT) to be executed.

Implement the fix so that unsupported methods and unknown/invalid targets are detected early (before any DB interaction), while keeping the HTTP behavior correct: 404 for invalid nested routes as above, and 405 with error code PGRST117 and the exact error message format “Unsupported HTTP method: <METHOD>” for unsupported methods.