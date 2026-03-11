Range requests are handled incorrectly when the requested range starts exactly at the total number of available rows/items (i.e., the first position equals the representation length). In this situation the server currently returns an empty successful partial response (HTTP 206 with an empty JSON array body), but per RFC 9110 the range is not satisfiable when first-pos is not less than the current length.

Reproduce with a resource that has exactly 1 item (so the valid index span is only the first item). Perform a GET request with Range headers such that the requested offset is 1 (equal to the total number of rows), for example calling the RPC endpoint `/rpc/getitemrange?min=1&max=2` with range headers requesting `1-2` while also requesting an exact count. The current response is:

- Status: 206
- Body: `[]`

This is incorrect. The server must treat this as an unsatisfiable range and respond with:

- Status: 416 (Range Not Satisfiable)
- JSON error body:
  `{"message":"Requested range not satisfiable","code":"PGRST103","details":"An offset of 1 was requested, but there are only 1 rows.","hint":null}`
- A `Content-Range` header indicating the total size, formatted as `*/<total>`, e.g. `Content-Range: */1` for a single-row resource.

The same rule should apply generally: if a client requests a range whose start offset is equal to the total available row count, the request must be rejected as not satisfiable (416) rather than returning an empty 206/200 response. Ensure the behavior is consistent with other existing invalid-range cases (e.g., start past last item) in terms of status code, error code `PGRST103`, error message text, and `Content-Range` formatting.