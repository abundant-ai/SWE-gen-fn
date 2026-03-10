When PostgREST encounters certain internal database errors during request handling, it returns an HTTP 500 to the client but does not emit any corresponding error information to stderr. Only a narrow subset of internal errors (notably connection pool acquisition timeouts) are currently printed to stderr as JSON lines like:

16/Nov/2023:22:45:48 +0000: {"code":"PGRST000","details":null,"hint":null,"message":"Timed out acquiring connection from connection pool."}

This makes operational debugging difficult because other internal database failures (for example PostgreSQL query cancellations due to statement_timeout) produce 500 responses visible in access logs on stdout, but stderr remains empty.

Change PostgREST so that all internal database errors that result in an internal server error (HTTP status >= 500) are logged to stderr in the same structured JSON error format used for other internal errors. In particular:

- If a request fails due to a PostgreSQL error that maps to an internal error response (e.g., statement_timeout / query canceled), PostgREST should write a single JSON error object to stderr containing the same fields that appear in the HTTP error response payload (e.g., code, message, details, hint).
- This behavior should not be limited to pool timeouts; it should apply uniformly to internal database errors surfaced during request execution.
- The stderr output should be emitted at the time the error occurs (i.e., during request processing) and should not require any special configuration beyond normal operation.

Reproduction example: execute a request that triggers a PostgreSQL statement timeout so that the client receives HTTP 500. Expected: stderr contains a structured JSON line describing the internal database error (including the PostgreSQL-derived error code/message as exposed by PostgREST for 500-class errors). Actual: stderr contains nothing for this case.