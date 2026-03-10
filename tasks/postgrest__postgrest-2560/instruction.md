When PostgREST is configured with a server-side row cap (e.g. `PGRST_DB_MAX_ROWS=100`), making a request with a client limit of zero (for example `GET /projects?limit=0`) can crash the server with a fatal error: `FatalError {fatalErrorMessage = "range without lower bound"}`. After this happens, a database connection from the pool can be permanently consumed; with a small pool (e.g. `PGRST_DB_POOL=1`) PostgREST may become unresponsive after a single such request.

The request `?limit=0` should be treated as a valid query that returns an empty result set (and appropriate range headers), and it must not trigger a fatal error even when `db-max-rows` is set. The logic that computes and applies request ranges/limits must correctly handle the “zero items requested” case without producing an invalid range (specifically, it must not create a range that lacks a lower bound).

Reproduction example:

1) Start PostgREST with `PGRST_DB_MAX_ROWS=100` (and any valid `PGRST_DB_ANON_ROLE` and database connection settings).
2) Call: `curl -X GET "http://localhost:3000/projects?limit=0"`

Current behavior: the server responds with a generic error (e.g. “Something went wrong”), logs a fatal error `range without lower bound`, and can leak/consume a pool connection.

Expected behavior: the request succeeds without crashing the server; it returns an empty JSON array for a collection endpoint, and emits a valid `Content-Range` header consistent with an empty page (and it must not degrade pool health or consume connections permanently). This should also work consistently when server-side `db-max-rows` limiting is applied, including with embedded resources and other query shapes that rely on range/limit computation.