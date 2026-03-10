PostgREST’s `Server-Timing` response header currently reports a `query` duration metric that lumps together multiple phases of handling a request, including transaction-scoped settings application and optional pre-request execution. This makes it impossible to understand how much time is spent in these phases separately, and the name `query` is misleading because it represents the whole database transaction rather than only the main SQL statement.

When a client performs requests such as GET/POST/PATCH/PUT/DELETE or an RPC call, the response should include a `Server-Timing` header with named metrics including `jwt`, `parse`, `plan`, `render`, and a metric representing the database transaction time named `transaction` (not `query`). In addition, an API request timing should be added so that overall API request time is measurable as a distinct metric (referred to as `ApiRequest` in the implementation).

Expected behavior:
- Responses that include `Server-Timing` must include a timing entry named `transaction`.
- The old timing name `query` should no longer be used.
- A timing for the API request should be recorded and surfaced via `Server-Timing` (the timing is called `ApiRequest` internally).
- This should work consistently across common HTTP methods (GET/POST/PATCH/PUT/DELETE) and RPC endpoints, without changing response bodies/status codes.

Actual behavior:
- The `Server-Timing` header includes `query` rather than `transaction` and does not expose an API request timing entry.

Update the timing instrumentation and `Server-Timing` header generation so these metrics are present with the correct names.