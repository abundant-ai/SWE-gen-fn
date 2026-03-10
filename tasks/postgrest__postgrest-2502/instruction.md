When a client request includes an invalid resource embedding (for example `GET /projects?select=*,wrong(*)` where `wrong` is not a valid embedded relationship), PostgREST correctly returns an error response (e.g. `{"code":"PGRST200", ... "message":"Could not find a relationship between 'projects' and 'wrong' in the schema cache"}`), but it still opens a database transaction even though no query plan can be built and no SQL should be executed.

This shows up in the PostgreSQL logs as an “empty transaction” for the failing request, typically:

- `BEGIN ISOLATION LEVEL READ COMMITTED READ ONLY`
- a `select set_config(...)` statement to set request GUCs
- `COMMIT`

The expected behavior is that if request planning fails (e.g. relationship not found in schema cache for embedding), PostgREST should reject the request without consuming a database pool connection and without opening a transaction at all (i.e., there should be no BEGIN/COMMIT for that request).

Fix the request/DB execution flow so that building/rejecting a plan does not require acquiring a DB connection. A DB connection (and transaction) should only be acquired once a valid plan exists and the server is ready to run the query. Ensure that any code paths that might have acquired a connection before failing can safely avoid starting a transaction, or can cleanly perform an optional rollback when appropriate, while keeping the same HTTP error response for the invalid embedding case.