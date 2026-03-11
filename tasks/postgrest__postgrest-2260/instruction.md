The schema introspection code currently fetches table metadata and column metadata via separate SQL queries (commonly exposed as something like `allTables` and `allColumns`). This split leads to unnecessary overhead when generating schema-dependent outputs such as the OpenAPI document at `/` (when requested with `Accept: application/openapi+json`) and when producing schema dumps, increasing memory usage and runtime without adding useful information.

Unify column retrieval into the table metadata query so that fetching the schema can be done in a single pass: each table returned by the table-introspection layer must include its corresponding column list inline, rather than requiring a separate query and a later merge step.

After this change, requests that depend on schema information must continue to behave exactly as before:

- `GET /` with `Accept: application/openapi+json` must return a valid OpenAPI JSON response with HTTP 200 and `Content-Type: application/openapi+json; charset=utf-8`.
- An OpenAPI request to a non-root path like `GET /items` with `Accept: application/openapi+json` must return HTTP 415.
- The produced OpenAPI JSON must still include the expected paths for tables and preserve table/comment-derived summaries and descriptions, including multi-line descriptions.

Additionally, the refactor must not regress memory characteristics of large requests tracked by the profiling-based memory checks (the server produces a `postgrest.prof` profile after handling requests). Schema-related work should not increase memory allocations compared to the previous behavior.

In short: merge column listing into table listing in the schema SQL/introspection pipeline, ensuring OpenAPI output and behavior remain unchanged and memory profiling checks continue to pass.