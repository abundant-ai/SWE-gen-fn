When an RPC call triggers a PostgreSQL error with SQLSTATE in the 53xxx class ("insufficient resources"), PostgREST currently returns HTTP 503 Service Unavailable. This is misleading because the PostgREST service is still healthy and able to serve other requests; only the particular database query failed due to a resource limit.

For example, if a function sets a very small `temp_file_limit` and then runs a query that exceeds it, PostgreSQL can return SQLSTATE `53400` with a message like:

```json
{"code":"53400","details":null,"hint":null,"message":"temporary file size exceeds temp_file_limit (1024kB)"}
```

Currently, calling the function via PostgREST (e.g., `POST /rpc/<function>` or `GET /rpc/<function>`) responds with HTTP 503 Service Unavailable (often including a `Retry-After` header), even though other endpoints continue to work normally.

PostgREST should not treat SQLSTATE 53xxx errors as a service-unavailable condition. Requests that result in any `53xxx` SQLSTATE (including `53400`) must return an HTTP 500 Internal Server Error response while preserving the existing JSON error body (including `code`, `message`, `details`, `hint`). The change should apply consistently to RPC endpoints and any other request type that surfaces PostgreSQL errors, so that `53400` (and the entire 53xxx class) no longer maps to 503.