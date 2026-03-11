Requests that use the query-plan media type need a new way to specify what the plan is generated for. Currently, when a client asks for a query plan using the Accept header `application/vnd.pgrst.plan` (or `application/vnd.pgrst.plan+json`), the server returns a JSON plan and supports `options=buffers` in the media type parameters, but there is no support for an additional `for` parameter.

Implement support for a `for` parameter on the `application/vnd.pgrst.plan` media type so that clients can request a plan “for” a particular context. The parameter must be parsed from the Accept header and preserved/handled consistently alongside existing `options` handling.

Concretely:

- The server must accept requests with `Accept: application/vnd.pgrst.plan` and respond with `Content-Type: application/vnd.pgrst.plan+json; charset=utf-8`.
- The server must accept `Accept: application/vnd.pgrst.plan+json; options=buffers` and respond with `Content-Type: application/vnd.pgrst.plan+json; options=buffers; charset=utf-8`, and the returned plan JSON must include buffer/block-related fields (as produced by PostgreSQL when buffers are enabled).
- Extend the above so that the same plan media type can include a `for` parameter (e.g. `Accept: application/vnd.pgrst.plan+json; for=<value>`), and the server must correctly interpret this parameter for plan generation while still returning the correct `Content-Type` (including any `options` and the `for` parameter, plus `charset=utf-8`).

If a request includes both `options` and `for`, both must be supported together (no parameter should be ignored or dropped from the response Content-Type when applicable). If `for` is invalid/unsupported, the request should fail with a clear client error rather than silently ignoring it.

The resulting behavior should continue to return valid plan JSON arrays where each element contains a `Plan` object (including `Total Cost`), and the plan costs should remain correct for filtered table/view queries; enabling `options=buffers` should continue to add the expected planning/execution block information on supported PostgreSQL versions.