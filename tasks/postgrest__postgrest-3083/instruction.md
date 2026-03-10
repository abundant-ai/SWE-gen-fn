PostgREST currently allows conditional requests based on the number of affected rows, but this behavior is either tied too tightly to specific response media types (e.g., object mode) or limited to checking only a single-row condition. This makes it impossible to express general “only proceed if the operation affects N rows” constraints across different request types, and it also leaves RPC calls without coverage/guarantees even though the documentation says affected-row limits work for RPC.

Add support for an affected-rows preference in the HTTP Prefer header that can be used to enforce conditions on how many rows a write operation (DELETE/PATCH and RPC) affects. The preference syntax must allow comparison operators and numeric limits:

Prefer: handling=strict; affected=<lt|lte|eq|gte|gt>.<number>

Multiple affected conditions may be provided in the same Prefer header, e.g.

Prefer: handling=strict; affected=gt.3,lte.20

Behavior requirements:

1) The affected preference must only be enforced when strict preference handling is enabled via Prefer: handling=strict. If handling=lenient is used, or if handling=strict is not specified, affected=… must have no effect (the request proceeds normally).

2) When handling=strict is enabled and an affected condition is not satisfied by the actual number of affected rows, PostgREST must reject the request with an HTTP 400 response and a structured JSON error. The error must use a new PGRST error code and message indicating that the affected-rows condition was not met (include enough information for a client to understand the condition failed).

3) When handling=strict is enabled and affected conditions are satisfied, the request should succeed normally.

4) The affected preference must be supported independently of the response media type and request method. In particular, it must work for:
- DELETE requests
- PATCH requests
- RPC calls (POST /rpc/…) where the function performs a write and results in a known affected-row count

Example scenario: if a DELETE would affect 1000 rows, then

DELETE /items
Prefer: handling=strict; affected=gt.3,lte.20

must fail with 400 because 1000 is not <= 20. If the same request is filtered so that it affects (for example) 4 rows, it must succeed.

Additionally, strict preference handling must continue to reject invalid preferences: when Prefer: handling=strict is present and the client supplies unknown/invalid preference tokens, PostgREST must return HTTP 400 with code PGRST122 and the message "Invalid preferences given with handling=strict" including which preferences were invalid. This strict-invalid-preference behavior must apply consistently for normal requests and for RPC calls, including when invalid preferences arrive via multiple Prefer headers.