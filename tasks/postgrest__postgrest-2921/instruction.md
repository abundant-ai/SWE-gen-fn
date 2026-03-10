Range requests against RPC endpoints can return an incorrect success response when the requested range starts exactly at the end of the available result set.

Reproduction: call an RPC endpoint that returns exactly 1 row total, and request a range whose first position is 1 (i.e., equal to the total number of rows). For example, make a GET request to `/rpc/getitemrange?min=1&max=2` with a `Range` header requesting items `1-2` and with `Prefer: count=exact` so the server knows the total row count.

Actual behavior: the server responds with HTTP status 206 (Partial Content) and an empty JSON array body (`[]`).

Expected behavior: the server must treat this as an unsatisfiable range (per RFC 9110: an int-range is satisfiable only if `first-pos` is strictly less than the current length). It should respond with HTTP status 416 (Range Not Satisfiable), include a `Content-Range` header of the form `*/<total>` (for this example `*/1`), and return a JSON error object with:

```json
{
  "message": "Requested range not satisfiable",
  "code": "PGRST103",
  "details": "An offset of 1 was requested, but there are only 1 rows.",
  "hint": null
}
```

This should apply generally: whenever a range request specifies an offset/start that is greater than or equal to the total number of rows in the result set (including the boundary case where it equals the total), the response must be 416 with the correct `Content-Range` and the `PGRST103` error payload, rather than returning an empty successful partial response.