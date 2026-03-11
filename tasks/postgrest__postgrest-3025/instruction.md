When performing a GET request that uses pagination (via offset/limit) together with an exact count request (`Prefer: count=exact`), PostgREST incorrectly returns HTTP 416 "Requested range not satisfiable" when the underlying result set is empty and `offset=0`.

For example, calling an RPC endpoint (or querying a table/view) that returns zero rows with a request like:

```http
GET /rpc/citation_by_software?offset=0&limit=3
Prefer: count=exact
```

currently yields:

- Status: 416
- Body:

```json
{
  "code": "PGRST103",
  "details": "An offset of 0 was requested, but there are only 0 rows.",
  "hint": null,
  "message": "Requested range not satisfiable"
}
```

This is incorrect because an offset of 0 is valid even when there are 0 rows available. The request should succeed and return an empty JSON array with HTTP 200.

Expected behavior:
- If the computed total number of rows is 0 and the requested offset is 0, the response must be successful (HTTP 200) and return `[]`.
- In this empty-result case, the response should also include a valid `Content-Range` indicating an empty range (for example `*/*` when the count is not requested, and a satisfiable empty range representation when `count=exact` is requested).

Behavior that must remain unchanged:
- If there are 0 rows and the client requests a nonzero offset (e.g. `offset=1` with `Prefer: count=exact`), PostgREST must continue to return HTTP 416 with error code `PGRST103`, include `Content-Range: */0`, and keep the error detail in the form "An offset of 1 was requested, but there are only 0 rows.".
- If there are N>0 rows and the client requests an offset greater than or equal to N (e.g. `offset=100` when there are 15 rows) with `Prefer: count=exact`, PostgREST must continue to return HTTP 416 with `PGRST103`, include `Content-Range: */15`, and an error detail like "An offset of 100 was requested, but there are only 15 rows.".

In short: fix the range validation logic so that `offset == 0` is treated as satisfiable even when the total row count is 0, while preserving 416 behavior for offsets that start past the end of the available rows.