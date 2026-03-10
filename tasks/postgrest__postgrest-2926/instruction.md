PostgREST returns incorrect HTTP status codes for insert/upsert operations in several cases, causing clients to misinterpret whether resources were created.

When performing insert/upsert via the REST API, the server currently uses status codes that don’t reflect whether any rows were actually inserted, and PUT does not distinguish between an insert vs an update.

1) POST should not return 201 Created if no rows were inserted.

Repro cases:
- A POST request with an empty JSON array payload (`[]`) currently returns 201, even though nothing is created.
- A POST upsert request using `Prefer: resolution=ignore-duplicates` (or equivalent “ignore duplicates” upsert behavior) currently returns 201 even when all input rows are duplicates and therefore zero rows are inserted.

Expected behavior:
- If the operation results in zero inserted rows (because the payload is empty or all rows are ignored as duplicates), the response status must be 200 OK (not 201).

Actual behavior:
- The server responds with 201 Created in these “no insert happened” cases.

2) PUT upsert should return 201 when it inserts new rows, and 200 when it only updates existing rows.

Repro case:
- A PUT request that performs an upsert currently responds with 200 OK regardless of whether the target row(s) were newly inserted or merely updated.

Expected behavior (RFC 7231 semantics for PUT):
- Return 201 Created when the PUT results in an insertion of a new row.
- Return 200 OK when the PUT updates an existing row (and does not create a new one).

Actual behavior:
- PUT always returns 200 OK.

The implementation must correctly detect, per request, whether rows were inserted vs updated vs no-op (no inserted rows), and choose the status code accordingly for POST and PUT upsert flows. The solution must work with upsert preferences such as "ignore duplicates" and with empty-array POST payloads, and must preserve existing behavior for normal inserts where rows are actually created (201) and for other methods (e.g., PATCH/DELETE) where status handling is unchanged.