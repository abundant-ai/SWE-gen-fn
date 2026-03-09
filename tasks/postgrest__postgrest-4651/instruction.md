PostgREST is currently hiding exceptions thrown from asynchronous server code paths, which makes failures difficult to debug because the logs do not show the real underlying error. In particular, when the HTTP server (Warp) encounters a fatal runtime error like a stack overflow, PostgREST may terminate the connection (clients see a connection error) but the stdout/stderr logs do not reliably include the Warp error message.

This needs to be fixed so that asynchronous exceptions are not swallowed/obscured by PostgREST’s async error-handling/logging layer. When a request causes the server to fail due to a stack overflow, PostgREST should log a line that includes the Warp error message text, e.g. it must contain the substring:

"Warp server error: stack overflow"

Reproduction scenario: run PostgREST against a sufficiently large schema, make an HTTP request that triggers a stack overflow (the client will likely observe a connection failure rather than an HTTP response), then inspect the PostgREST process output. Expected behavior is that the output contains the Warp server error message including the stack overflow text. Actual behavior is that the exception is hidden or replaced with a less-informative log entry, and the Warp server error text is missing.

Implement the change so that PostgREST logs the original async exception information from the Warp server layer instead of suppressing it, ensuring fatal async exceptions are visible in logs with the correct message content.