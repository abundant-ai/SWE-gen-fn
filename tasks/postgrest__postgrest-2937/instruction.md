PostgREST currently provides limited visibility into where time is spent during a request. Users can get database execution timing via the EXPLAIN-based plan feature, but there is no built-in way to measure (a) how long JWT decoding/authentication takes, or (b) how long PostgREST spends parsing/planning the request before sending it to PostgreSQL, or (c) additional time spent after the database responds (e.g., obtaining/processing the query response).

Implement support for the standard HTTP response header `Server-Timing` to expose per-request duration metrics. When enabled, responses should include a `Server-Timing` header with at least a `jwt` metric representing the time spent decoding/validating the JWT for the request.

Behavior requirements:

- Requests across common HTTP methods must include a `Server-Timing` response header when the feature is enabled, including GET, POST (including insert with `Prefer: return=representation`), PATCH, PUT, DELETE, and RPC calls.
- The header must be present even on responses with no body and no `Content-Type` (e.g., typical 204 responses for PATCH/DELETE), i.e., the presence/absence of a body must not prevent emitting `Server-Timing`.
- The `Server-Timing` header must be formatted as a standard Server-Timing value containing one or more metrics with `dur` values in milliseconds. At minimum it must include the `jwt` metric with a duration, e.g. `Server-Timing: jwt;dur=34` (exact numbers will vary).
- The feature should be possible to enable without paying the measurement overhead on every request. It must be enabled when either:
  - the client sends `Prefer: server-timing=include`, or
  - server-side configuration for plan/analysis timing is enabled (the same configuration that enables database plan support).

Expected result: When the feature is enabled and a client performs any of the request types above, the response includes `Server-Timing` and contains the `jwt` timing metric with a valid `dur` value in milliseconds. Currently, these responses do not include `Server-Timing` at all, preventing users from debugging JWT decoding latency and other request lifecycle timing.