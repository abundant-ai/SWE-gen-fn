PostgREST v13+ shows a regression under large/dynamic schemas (tens of thousands of tables): memory usage continuously grows over time until the process is killed by the OOM killer, and some tables created after PostgREST startup intermittently cannot be queried (clients see connection aborts like `ServerDisconnectedError` / `RemoteDisconnected('Remote end closed connection without response')`). Both issues do not reproduce on v12.2.3.

The failures correlate with relation-hint generation used when a requested resource/relationship is missing from the schema cache. When a request references a table or relationship that does not exist in the current schema cache (e.g. `GET /unknown-table` or `GET /unknown-table?select=unknown-rel(*)`), PostgREST attempts to compute a “did you mean …” style hint by running fuzzy search over the set of database tables. On very large schemas, repeatedly constructing the fuzzy-search index is expensive and can lead to severe performance problems and unbounded memory growth. This can also destabilize connections, leading to abrupt disconnects, and contributes to the observed inability to query some newly created tables until PostgREST is restarted.

Fix the relation-hint calculation so that fuzzy search index construction is not repeatedly re-created on each request that misses the schema cache. The schema cache should hold a reusable/memoized fuzzy-search index of database tables (built once per schema cache load/reload) that is used to compute hints for subsequent missing-table/missing-relationship errors.

Expected behavior:
- For requests referencing non-existent tables/relationships, PostgREST should return a normal error response (e.g. HTTP 404 with error code `PGRST205`) without stack overflow or connection aborts.
- After the first request that triggers fuzzy matching, subsequent requests that also miss the schema cache (e.g. another `GET /unknown-table`) should be significantly faster and should not re-do costly fuzzy-index construction.
- Memory usage should remain stable over time under load (no steady growth leading to OOM) even with very large numbers of tables.
- The schema cache loading phase should remain performant on larger schemas (schema cache load time should stay within a reasonable bound, e.g. sub-second for a moderately large fixture schema).

Actual behavior to resolve:
- Under v13+ behavior, repeated requests that miss the schema cache cause excessive CPU/memory usage, memory grows continuously until OOM, and some requests to recently created tables can result in `ServerDisconnectedError`/`RemoteDisconnected` until a restart.

Implement the schema-cache-level memoization for the fuzzy index used by relation-hint calculation, and ensure it is correctly refreshed when the schema cache is reloaded so hints remain accurate without leaking memory.