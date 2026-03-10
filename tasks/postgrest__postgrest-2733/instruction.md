Remote procedure call (RPC) responses have inconsistent JSON shaping and incorrect handling of procedure return types after recent internal refactors around procedure metadata. In particular, logic for building the JSON response for functions/procedures is split across multiple code paths, and some return-type combinations (scalar vs composite, set-returning vs single-row, and void) can lead to incorrect response bodies and/or incorrect HTTP semantics.

The server should treat procedure output consistently by routing procedure result construction through a single JSON-wrapping path (exposed as an `asJsonF` wrapper) so that all RPC responses are encoded the same way regardless of how the procedure is invoked (POST with JSON body vs GET with query parameters) and regardless of the procedure’s declared return type.

Reproduction scenarios that must work:

1) Set-returning procedure pagination
- Calling the RPC endpoint for a set-returning procedure with a `Range` header must return a JSON array body containing only the requested window.
- The response must include a `Content-Range` header reflecting the window and total when known.
- When a total count is not requested, the response status must be `200` and `Content-Range` should use `*` for total (e.g. `0-0/*`).
- When the client requests a total count via `Prefer: count=exact` (or the project’s equivalent count-preference), the response status must be `206` for partial responses and `Content-Range` must include the total number of rows (e.g. `0-0/2`).
- These behaviors must be identical for POST `/rpc/<proc>` with a JSON body and GET `/rpc/<proc>?...` with query parameters.

2) HEAD requests to RPC endpoints
- A `HEAD` request to an RPC endpoint must not include a response body.
- It must still return the same status code and headers (`Content-Type: application/json; charset=utf-8` when applicable, and any `Content-Range` headers) as the corresponding GET/POST would.

3) Procedure return type handling
- Procedures that return a set of rows (SETOF) must be encoded as JSON arrays.
- Procedures that return a single composite row must be encoded as a JSON object (or an array with one element only if the endpoint semantics require set-returning behavior; the important part is consistency between GET and POST and across the code paths).
- Procedures that return scalar values must be encoded consistently (e.g. a JSON scalar or a one-field object, depending on the API’s established contract), and must not fail due to missing/incorrect return-type metadata.
- Procedures that return no value (void) must not attempt to JSON-encode a nonexistent value; the response should follow the API’s existing rules for void returns (commonly an empty body with an appropriate status).

4) Prefer parameter handling on RPC
- The RPC endpoint must not rely on the deprecated/removed behavior of interpreting `Prefer: params=multiple-objects` for RPC parameter passing. Parameter passing should follow the current supported behavior, and removal of that preference must not break standard RPC calls.

If any of the above currently results in incorrect status codes (e.g. returning 200 instead of 206 when count is requested and the response is ranged), incorrect/missing `Content-Range`, incorrect JSON shape, or runtime errors during encoding, fix the procedure JSON response construction so it always goes through `asJsonF` and uses the correct return type information for procedures.