When PostgREST returns an HTTP 503 to the client (for example during a transient database disconnect/reconnect scenario), it currently only emits the standard request access log line, but it does not emit the corresponding error details to stderr. This makes 503 responses effectively silent from an error-logging perspective, even though other server errors (e.g., HTTP 500) correctly log a JSON error object to stderr.

Reproduction example: trigger a condition where PostgREST returns 503 (such as when PostgreSQL terminates an existing connection due to recovery conflict and PostgREST immediately attempts to reconnect). The client sees an access log like:

127.0.0.1 - <role> [<timestamp>] "GET /rpc/<fn> HTTP/1.1" 503 - "" "node"

but there is no preceding stderr log entry describing the error. By contrast, for a 500 response PostgREST emits an error JSON line to stderr such as:

{"code":"57014","details":null,"hint":null,"message":"canceling statement due to statement timeout"}

and then the access log line.

Expected behavior: whenever PostgREST returns an HTTP 503 response, it must also log the underlying error information to stderr in the same way it does for other error statuses (notably 500). The stderr output should include the relevant error fields (at minimum a message, and where available code/details/hint) so operators can diagnose why 503s are happening. Actual behavior: 503 responses produce no stderr error output, only the access log line.