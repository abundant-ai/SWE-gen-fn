When requesting a singular JSON object representation (using an Accept header like `application/vnd.pgrst.object+json` or `application/vnd.pgrst.object`), PostgREST returns an error when the query result does not contain exactly one row. This behavior is used by clients like `maybeSingle()` (e.g., in postgrest-js/supabase-js) to interpret “no rows” as a non-exceptional condition; however, the current error response details are not specific enough for clients to reliably distinguish “0 rows” from “multiple rows”, and the response can be surfaced as a confusing 406 error in network logs.

Update the singular/object error response so that the `details` field is improved to clearly report how many rows were returned in the failing case, and do so consistently for both read (GET) and write operations (e.g., PATCH with `Prefer: return=representation`).

Expected behavior:
- If a request asks for a singular object (`Accept: application/vnd.pgrst.object+json` or `application/vnd.pgrst.object`) and the result contains 0 rows, the response must be an error with status 406 and a JSON body that includes a `details` string explicitly stating the row count (e.g., “The result contains 0 rows”), along with the existing error `message` (“JSON object requested, multiple (or no) rows returned”), an error `code` (e.g., `PGRST116`), and `hint` set to null.
- If the result contains more than 1 row (e.g., 4 rows), the response must be an error with status 406 and a JSON body whose `details` field explicitly states that row count (e.g., “The result contains 4 rows”), preserving the same `message`, `code`, and `hint` shape.
- If the result contains exactly 1 row, the response must succeed and return the object with the appropriate singular content type.

Actual behavior to fix:
- The error `details` field is currently phrased in a way that is less machine/consumer friendly (e.g., “Results contain 0 rows, application/vnd.pgrst.object+json requires 1 row”) and/or is inconsistent between scenarios, making it hard for clients to distinguish 0-row from multi-row outcomes reliably.

Make sure the improved `details` wording and the presence/shape of fields (`details`, `message`, `code`, `hint`) are consistent across endpoints and methods that can produce singular responses.