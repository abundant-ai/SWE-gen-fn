Bulk UPDATE/DELETE requests can unintentionally mutate a very large number of rows. For example, even with safeguards like pg-safeupdate, a request such as `DELETE /employees?salary=gt.1000` may delete far more rows than intended. PostgREST already has special-case behavior where using the singular JSON media type (`application/vnd.pgrst.object+json`) enforces exactly 1 affected row for UPDATE/DELETE, rejecting the request if the mutation affects 0 or more than 1 row. This safety mechanism needs to be generalized and integrated with request limits.

When a client sends an UPDATE (PATCH) or DELETE request to a table endpoint with a `limit` query parameter, PostgREST should be able to apply that limit to the number of rows that can be mutated, so that the mutation only affects up to the requested number of rows. For example:

`PATCH /projects?limit=1` with a JSON body updating fields should update only one matching row, not all matching rows.

Similarly, `DELETE /projects?limit=1` should delete only one matching row.

This limited-mutation behavior must only apply to tables (not views). If the target is a view, PostgREST should not attempt to apply a row-limit technique to UPDATE/DELETE.

In addition, the server-side `max-rows` setting (used to restrict how many rows can be returned in read responses) currently produces misleading behavior for bulk inserts when `Prefer: return=representation` is used: inserting more than `max-rows` rows succeeds, but the returned representation is truncated to `max-rows`. The correct behavior is that `max-rows` should not affect insertions (POST) in this way. A bulk insert of 1500 rows with `Prefer: return=representation` should return the full inserted representation (subject to the client’s own limits), rather than being capped to `max-rows`.

Expected behavior:
- PATCH/DELETE against table resources should support limiting the number of mutated rows based on the `limit` query parameter, so only up to that many rows are updated/deleted.
- The feature should not be applied to view resources.
- Server-side `max-rows` should not truncate returned representations for bulk inserts (POST) when `Prefer: return=representation` is requested.

Actual behavior to fix:
- UPDATE/DELETE operations can affect an unbounded number of rows even when a client intends to operate on a small subset.
- With `max-rows` configured, bulk insert responses with `Prefer: return=representation` are truncated, making it appear as if fewer rows were inserted than actually were.