PostgREST currently lacks a way to observe end-to-end timing breakdowns for a request: users cannot see how long JWT decoding takes, how long request parsing/planning takes, how long the database query takes, or how long it takes to receive/stream/render the query response. The existing EXPLAIN execution plan only exposes query time and does not cover the other phases.

Add support for emitting the standard HTTP `Server-Timing` response header with multiple duration metrics for each request. The header must include at least these metric names, each with a `dur=<milliseconds>` value: `jwt`, `plan`, `query`, and `render`.

Example format:

```http
Server-Timing: jwt;dur=34, plan;dur=47.2, query;dur=53, render;dur=15
```

The feature must work consistently across the main request types PostgREST supports, including reads and writes and RPC calls. In particular, successful responses for GET, POST (including when `Prefer: return=representation` is used), PATCH, PUT, DELETE, and POST to `/rpc/...` should all include a well-formed `Server-Timing` header containing all four metrics. For cases where PostgREST returns an empty body (e.g., 204 responses), the `Server-Timing` header must still be present.

The emitted `Server-Timing` values should be parseable as numbers (integer or decimal milliseconds). Each metric must be present exactly as a separate entry in the comma-separated header value, and each must include the `;dur=` parameter.

To avoid overhead on all requests, the header should only be enabled when the client requests it via `Prefer: server-timing=include` and/or when server-side configuration enabling plan/timing is turned on (for example via the existing `db-plan-enabled` setting). When neither condition is met, PostgREST should not add the `Server-Timing` header.

If the header is enabled, it should reflect the durations of the corresponding phases for that request (JWT verification/decoding, request planning, database query execution, and rendering/receiving the response) and must not break existing response headers or content-type behavior.