Range requests against RPC endpoints can return an incorrect successful response when the requested range starts exactly at the end of the available result set. 

Reproduction example: a GET to `/rpc/getitemrange?min=1&max=2` returns exactly 1 row total (so the only valid first position is 0). When the client requests a range with a first position of 1 (e.g. `Range: 1-2`), the response currently comes back as a successful but empty partial/empty response (status 206 with body `[]`).

This is wrong: per HTTP range semantics, a range is satisfiable only if `first-pos < current length`. If `first-pos == length`, the server must reject it as not satisfiable.

Expected behavior: when a client requests a range whose start offset is equal to the number of available rows (including the case of 0 rows with nonzero start), the server must respond with:

- HTTP status `416 Requested Range Not Satisfiable`
- JSON error body:
  - `message`: "Requested range not satisfiable"
  - `code`: "PGRST103"
  - `details`: formatted like `"An offset of <offset> was requested, but there are only <total> rows."`
  - `hint`: null
- A `Content-Range` header of the form `"*/<total>"` (for this case, `"*/1"`)

Actual behavior: for `offset == total` (e.g. offset 1 when total rows is 1), the server returns status 206 (or otherwise a successful response) with an empty JSON array body.

Fix the range validation so that any request whose computed start position is greater than or equal to the total available rows is treated as unsatisfiable and produces the 416 error response above. This should work both for explicit `offset` query parameter usage and for HTTP `Range` header usage (e.g. `ByteRangeFromTo 1 2`) when the effective first position equals the total.