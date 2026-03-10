When PostgREST receives a request for a table that does not exist and the request also contains an embedded resource selection, the server can crash with a stack overflow and the client sees an empty reply from the server instead of a proper JSON error response.

Reproduction:
- Run PostgREST against a schema where the requested root resource and embedded resource do not exist.
- Send a request like:
  
  `GET /x?select=y(*)`

Actual behavior:
- The request fails with an “Empty reply from server” on the client side.
- PostgREST logs show a `stack overflow` during request handling (observed especially in development environments that enable very small RTS stack limits such as `-K1K`).

Expected behavior:
- The server must not crash. It should return an HTTP 400 response with a JSON error body indicating the missing relationship, e.g. an error with code `PGRST200` and a message like:
  
  `Could not find a relationship between 'x' and 'y' in the schema cache`
  
  and details similar to:
  
  `Searched for a foreign key relationship between 'x' and 'y' in the schema 'public', but no matches were found.`

Notes on the suspected cause and required change:
- The crash is triggered while building the error “hint” for missing relationships using fuzzy matching of candidate relationship names.
- The fuzzy matching implementation must be adjusted so that generating this hint does not cause a stack overflow / space leak under small-stack configurations.
- After the fix, a request like `GET /unknown-table?select=unknown-rel(*)` must reliably return HTTP 400 rather than crashing, even when leak detection/small-stack RTS options are enabled.