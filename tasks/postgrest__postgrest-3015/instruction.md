When calling an RPC endpoint whose underlying PostgreSQL function returns a single row (i.e., not a set-returning function), PostgREST currently performs an unnecessary COUNT query as part of building the response (typically to support pagination/Content-Range semantics). This extra count increases the query plan cost and shows up in execution plans even though the total is already known to be 1 (or the endpoint is otherwise not pageable like a set).

The RPC execution logic should avoid issuing a COUNT (and avoid wrapping/planning the call in a way that forces a count) when the RPC result is known to be a single row. The request should still return the same response body and status codes as before for single-row RPCs; the only change is that the generated SQL/plan should not include the extra count operation.

In particular, when requesting query plans using the media type `application/vnd.pgrst.plan+json`, the reported total cost for RPCs that return a single row should reflect the removal of the redundant count. This optimization should not break existing pagination/count behavior for RPCs that return sets: set-returning RPCs must continue to support `Range` headers, `limit`/`offset`, and `Prefer: count=exact` including correct `Content-Range` headers and 206 responses when the response is partial.

Expected behavior:
- Single-row RPC calls should not trigger a COUNT as part of the generated query.
- Plan output (`application/vnd.pgrst.plan+json`) should show a reduced plan cost consistent with not performing the count.
- Set-returning RPCs must continue to behave the same: pagination works with `Range` or `limit`/`offset`, and requesting an exact count still produces correct partial-content semantics (`206`) and correct `Content-Range` totals.

Actual behavior:
- Single-row RPC calls still perform a COUNT internally, inflating plan cost and adding unnecessary work even though the result cardinality is 1.