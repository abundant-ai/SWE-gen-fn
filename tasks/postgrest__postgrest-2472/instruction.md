When a client requests a range using `offset`/`limit` and also sends `Prefer: count=exact`, PostgREST can correctly detect that the requested range is not satisfiable (HTTP 416), but it currently returns an empty JSON array (`[]`) as the response body. This makes client libraries treat the failure as having no structured error payload, even though the HTTP status is 416, and users cannot access the reason for the failure.

Reproduction example:

```bash
curl -i "http://localhost:3000/items?offset=16" -H "Prefer: count=exact"
```

Current behavior:
- Response status: `416 Requested Range Not Satisfiable`
- Response body: `[]` (no error object)

Expected behavior:
- For a 416 caused by an out-of-bounds `offset` when `Prefer: count=exact` is used, the response must be a JSON error object (not an empty array) with:
  - `message`: "Requested range not satisfiable"
  - `code`: "PGRST103"
  - `details`: a human-readable explanation including the requested offset and the total number of available rows, e.g.:
    - "An offset of 1 was requested, but there are only 0 rows."
    - "An offset of 100 was requested, but there are only 15 rows."
  - `hint`: null
- The response must also include an appropriate `Content-Range` header indicating the total rows:
  - When there are 0 rows: `Content-Range: */0`
  - When there are N rows: `Content-Range: */N`

The change should apply specifically to cases where PostgREST can determine the total row count (i.e., when `Prefer: count=exact` is present) and the requested `offset` is greater than the last available index (including the case where there are no rows but a nonzero offset is requested). In contrast, when no exact count is requested and PostgREST cannot know the maximum range, requesting an offset beyond the end should continue to return `200 OK` with an empty array.

Also ensure that other 416 "range" errors continue to return structured JSON error objects (for example, negative limits already return an error message) and that this change does not introduce fatal errors or crashes for unusual range inputs.