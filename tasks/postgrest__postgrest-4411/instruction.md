PostgREST’s schema cache reload “wait” behavior can’t currently be tested or controlled with enough granularity because there isn’t a clear separation between (1) time spent running schema cache SQL queries and (2) time spent processing the query results (including relationship processing). This makes schema reload waiting behavior flaky and prevents reliably asserting that some requests should block on schema cache availability while not unnecessarily blocking on relationship loading.

Add support for three separate internal configuration variables that independently introduce delays at distinct points of schema cache loading:

- `internal-schema-cache-query-sleep`: adds a delay during schema cache SQL query execution (e.g., by doing an internal `pg_sleep` so the connection is occupied while the query runs).
- `internal-schema-cache-load-sleep`: adds a delay after schema cache SQL queries finish but before their results are processed into the in-memory schema cache.
- `internal-schema-cache-relationship-load-sleep`: adds a delay specifically while processing relationship query results (so relationship loading can be made slow without necessarily delaying base schema availability).

These must be configurable via environment variables in the usual PostgREST config style:

- `PGRST_INTERNAL_SCHEMA_CACHE_QUERY_SLEEP`
- `PGRST_INTERNAL_SCHEMA_CACHE_LOAD_SLEEP`
- `PGRST_INTERNAL_SCHEMA_CACHE_RELATIONSHIP_LOAD_SLEEP`

Expected behavioral outcomes when a schema cache reload is triggered (for example via the notification RPC used to reload the cache):

1) Requests that require resource embedding (e.g., a request like `GET /tpopmassn?select=*,tpop(*)`) should wait for relationship loading when relationship loading is intentionally slowed via `PGRST_INTERNAL_SCHEMA_CACHE_RELATIONSHIP_LOAD_SLEEP`. With relationship load sleep set to about 5 seconds, the request should take longer than 5 seconds and still return `200`.

2) Requests that do not require resource embedding (e.g., `GET /tpopmassn`) should only wait until the base schema cache is available, not until relationship loading completes. With `PGRST_INTERNAL_SCHEMA_CACHE_LOAD_SLEEP` set to about 1 second and `PGRST_INTERNAL_SCHEMA_CACHE_RELATIONSHIP_LOAD_SLEEP` set to about 5 seconds, the request should return `200` and take longer than 1 second but still complete in under 5 seconds.

The new configuration variables must be parsed and applied so that:

- The “query sleep” affects only the time spent executing schema queries.
- The “load sleep” affects only the gap between query completion and processing results into the schema cache.
- The “relationship load sleep” affects only processing of relationship query results.

This separation is required to make schema cache reload waiting deterministic and to ensure that non-embedding requests are not blocked by slow relationship processing while embedding requests do wait appropriately.