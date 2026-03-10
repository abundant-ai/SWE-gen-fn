When inserting or updating rows, PostgREST can reject requests that reference columns not present in its current schema cache. This commonly happens if a new column is added in PostgreSQL after PostgREST has started and the schema cache has not been reloaded.

Reproduction example:
1) Start PostgREST.
2) Run in SQL: `alter table test.projects add column new text;`
3) Try to insert/update using that column, e.g.:
- `POST /projects` with JSON body `{"id":343,"new":"foo"}`
- `POST /projects?columns=id,new` with the same body
- `PATCH /projects?id=eq.1` with JSON body `{"new":"foo"}`

Current behavior: the server returns HTTP 400 with error code `PGRST204` and message like:
`Column 'new' of relation 'projects' does not exist`
This message is misleading because the column *does* exist in PostgreSQL; it is missing from PostgREST’s schema cache (or otherwise not available to the API due to stale schema metadata). It also reads like a raw PostgreSQL error rather than a PostgREST-specific validation failure.

Expected behavior: for inserts and updates that reference a column unknown to the current schema cache, PostgREST should still return `PGRST204` but with a clarified message that indicates the column is not present in the schema cache / schema cache is out of date, and that a schema cache reload is required to pick up newly added columns. This should apply consistently to both INSERT (POST) and UPDATE (PATCH), and regardless of whether the request uses a `columns` query parameter.

The response should remain a JSON error object with fields `code`, `message`, `details`, and `hint`, but the `message` must be updated to the new clarified wording so users understand the fix is to refresh/reload the schema cache rather than assuming the database column truly does not exist.