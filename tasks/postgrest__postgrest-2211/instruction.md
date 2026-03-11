PostgREST’s limited update/delete behavior is incorrect/inconsistent when clients attempt to apply row limits, especially on views, and the server currently relies on an implicit fallback ordering that can produce non-deterministic results.

When performing UPDATE/PATCH or DELETE requests where a client intends to affect only a limited number of rows, the server should only allow the operation when the target rows are deterministically ordered. In particular:

If the target is a view, applying a limit should work only when the request includes an explicit `order` parameter (for example, `?order=id.asc`). Without an explicit order, PostgREST must reject (or otherwise not perform) limited update/delete on views because the affected rows would be ambiguous.

Additionally, PostgREST currently falls back to using `ctid` as a default ordering when none is supplied. This fallback must be removed. After this change, limited update/delete on tables should also require an explicit `?order=...` to ensure deterministic behavior; the server must not silently pick an internal ordering.

Finally, when a `limit` is applied for these write operations, PostgREST should apply an implicit `row_count` equal to the requested limit. This should affect the response metadata consistently (for example, Content-Range / count behavior) so that the operation’s reported row count aligns with the limit even when an exact count is not requested.

Reproduction example:
- A DELETE like `DELETE /items?order=id.asc&limit=1` should delete at most one record and report metadata consistent with a row count of 1.
- The same kind of request against a view should only be allowed when `order` is explicitly provided; otherwise the server should not proceed with a potentially non-deterministic limited delete/update.

Implement the necessary changes so that: (1) views support limited update/delete only with explicit ordering, (2) the `ctid` ordering fallback is removed, and (3) limited write operations implicitly set `row_count` equal to the given `limit`, resulting in consistent response metadata.