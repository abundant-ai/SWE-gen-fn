Calling an RPC function that is used as a media type handler can currently fail when the function returns a NULL row. For example, if a handler function is declared to return a custom media type (e.g. a domain like "application/vnd.twkb" over bytea) and the underlying query returns no value/NULL for the selected row, requesting that RPC with an appropriate Accept header results in an internal error response.

Reproduction example:

1) Create a SQL function that returns a custom media type and selects a value that may be NULL (e.g. selecting a geometry converted to TWKB from a table by id).
2) Call the function through PostgREST, requesting that media type:

```bash
curl "http://localhost:3000/rpc/get_line?id=3" -H "Accept: application/vnd.twkb"
```

Current behavior: the server returns an error like:

```json
{"code":"PGRSTX00","details":null,"hint":null,"message":"RowError 0 2 UnexpectedNull"}
```

Expected behavior: when the handler function produces no value/NULL for the requested row, the request should not fail with a RowError/UnexpectedNull. Instead, it should behave like an empty result for the RPC call (consistent with how other endpoints behave when there is no matching row), while still honoring content negotiation for the requested custom media type. Non-null rows must continue to work normally and return 200 OK with the expected Content-Type (e.g. "application/vnd.twkb").

Fix the RPC/custom media handler response processing so that NULL/empty rows returned by a handler function are handled gracefully (no PGRSTX00 RowError UnexpectedNull) and produce the correct HTTP response semantics for an empty result.