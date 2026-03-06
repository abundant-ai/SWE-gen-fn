When a client requests GeoJSON output (e.g., with the HTTP header `Accept: application/geo+json`) PostgREST currently attempts to build a GeoJSON response by executing a query that calls PostGIS functions such as `ST_AsGeoJSON(...)`. On databases where PostGIS is not installed (or the relevant function is unavailable), the request still hits the database and fails at execution time with an error like:

```json
{"code":"42883","details":null,"hint":"No function matches the given name and argument types. You might need to add explicit type casts.","message":"function st_asgeojson(record) does not exist"}
```

This is undesirable because PostgREST should not run a query that is guaranteed to fail when PostGIS support is unavailable, and it should fail early without issuing the main SQL query.

Reproduction:
1) Run PostgREST against a PostgreSQL instance without PostGIS installed.
2) Send a request to any table endpoint (for example `/shops`) with `Accept: application/geo+json`.

Actual behavior:
- PostgREST executes the main query containing `ST_AsGeoJSON(...)` and returns a database error (`42883`) about the missing function.

Expected behavior:
- PostgREST should detect PostGIS availability during schema cache construction and use that information when setting up its initial media handlers.
- If PostGIS is unavailable, GeoJSON (`application/geo+json`) should not be offered/selected as a response format, and a request that explicitly asks for it should fail immediately without executing the main query.
- The failure should be a clean PostgREST-level error response (rather than a PostgreSQL “function does not exist” execution error), and logs should not show the failing `ST_AsGeoJSON(...)` query being run.

Implement the needed plumbing so that `initialMediaHandlers` can determine whether PostGIS is available based on schema cache construction, and ensure GeoJSON behavior follows the expectations above.