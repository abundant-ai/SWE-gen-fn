Requests with an out-of-bounds offset (or otherwise unsatisfiable range) can return HTTP 416 (Requested Range Not Satisfiable) but with a malformed/truncated response body in newer versions. This regression is most visible when the client requests an exact count (e.g., using the header `Prefer: count=exact`). Some clients then surface an unusable error like `error: { message: '{"' }`, because the response body is not valid JSON and appears cut off.

Reproduction example:

```bash
curl -i "http://localhost:3000/items?offset=2000" -H "Prefer: count=exact"
```

Current behavior (bug):
- The server responds with status 416, but the error body is malformed/truncated such that JSON clients cannot parse it.
- As a result, client libraries may only expose `status` and `statusText` (e.g., `416 Range Not Satisfiable`) and provide an empty/garbled `error.message`.

Expected behavior:
- For an unsatisfiable range request (e.g., requesting an offset beyond the number of available rows), the server must return a well-formed JSON error object (with `Content-Type: application/json`) and a correct `Content-Range` header indicating the total size.
- The response status must be `416`.
- The JSON error body must include these fields:
  - `message`: exactly `"Requested range not satisfiable"`
  - `code`: exactly `"PGRST103"`
  - `details`: a human-readable explanation that includes the requested offset and the total number of rows, e.g. `"An offset of 100 was requested, but there are only 15 rows."`
  - `hint`: `null`
- The `Content-Range` header must use the `*/<total>` form for invalid ranges, for example:
  - When there are 0 rows total and an offset of 1 is requested: `Content-Range: */0`
  - When there are 15 rows total and an offset past the end is requested: `Content-Range: */15`

The fix should ensure that this 416 error response is never truncated/malformed and remains parseable JSON for the invalid-range scenarios, particularly when `Prefer: count=exact` is present.