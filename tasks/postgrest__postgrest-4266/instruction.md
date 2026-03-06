When a client requests GeoJSON output using the `Accept: application/geo+json` header, PostgREST can generate SQL that calls `ST_AsGeoJSON(...)`. On databases where PostGIS is not installed (or where the `st_asgeojson` function is not available for the requested argument type), PostgREST still executes the main query and the request fails with a PostgreSQL error like:

```json
{"code":"42883","details":null,"hint":"No function matches the given name and argument types. You might need to add explicit type casts.","message":"function st_asgeojson(record) does not exist"}
```

This behavior is undesirable because PostgREST should not attempt to run a GeoJSON-formatted query when the required PostGIS support is unavailable, and it should fail fast without hitting the database for the main query.

Fix the GeoJSON response negotiation / media handler selection so that `Accept: application/geo+json` does not result in a query using `ST_AsGeoJSON` unless PostgREST has determined that the required PostGIS GeoJSON functionality is available for the current database/schema. PostgREST should detect this capability during schema cache loading (or an equivalent pre-request capability check) and use that to decide whether GeoJSON can be served.

Expected behavior:
- If PostGIS (and specifically GeoJSON output support via `ST_AsGeoJSON`) is available, requests with `Accept: application/geo+json` should behave as before and return GeoJSON.
- If PostGIS/`ST_AsGeoJSON` is not available, a request with `Accept: application/geo+json` should fail immediately with a clear PostgREST error response indicating the requested media type cannot be produced (rather than executing the main SELECT and surfacing a PostgreSQL `42883` “function ... does not exist” error).
- When GeoJSON is not supported, the system should not execute the GeoJSON-producing main query (so enabling query logging should not show a query containing `ST_AsGeoJSON` being run for such a request).

Reproduction example:
- Run PostgREST against a PostgreSQL instance without PostGIS.
- Request an endpoint with `Accept: application/geo+json` (for example: `GET /shops`).
- Currently it triggers SQL that includes `coalesce(json_agg(ST_AsGeoJSON(...)))` and fails with `function st_asgeojson(record) does not exist`; this should be replaced by an early PostgREST-level rejection of GeoJSON output for that database.