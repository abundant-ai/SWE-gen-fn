PostgREST becomes very slow and/or uses excessive memory when calculating “relation hints” (the suggestions shown when a client requests an unknown relationship/embed). This is especially problematic on large schemas: a request that references a non-existent relationship can trigger an expensive fuzzy search over many possible candidates, leading to severe performance degradation and, in extreme cases, stack overflow or runaway resource usage.

Reproduction scenario:
- Run PostgREST against a database with a large schema (many tables/views/relationships).
- Make a request that includes an embed of a relationship that does not exist, e.g.:
  GET /unknown-table?select=unknown-rel(*)

Current behavior:
- The server spends an excessive amount of time building/processing relation-hint candidates, may consume a lot of memory, and can fail catastrophically (e.g. stack overflow) when trying to produce fuzzy suggestions.
- Initial schema cache loading can become too slow on large schemas.
- Even when the first request eventually returns an error, subsequent requests for similarly non-existent resources can remain slow instead of becoming fast after any necessary indexing/warmup.

Expected behavior:
- Requests for non-existent tables/relationships must fail quickly and safely, returning an HTTP 404 JSON error with code "PGRST205" (rather than crashing or exhausting resources).
- Relation hint calculation must not cause stack overflow or unbounded recursion/processing when the relationship does not exist.
- After the server has performed any one-time preparation needed for fuzzy search/hinting, subsequent requests for a non-existent table/relationship should be significantly quicker than the first request (i.e., the expensive portion should not repeat each time).
- On large schemas, schema cache loading should remain performant; the startup log line of the form:
  "Schema cache loaded in <N> milliseconds"
  should report a duration that stays under a reasonable upper bound (on the order of hundreds of milliseconds for the referenced large schema scenario).

Implement/fix the relation hint calculation and any related caching/indexing so that large-schema workloads do not exhibit high memory usage, slowdowns, or stack overflow when handling unknown relationships, while preserving the correct error response (404 with code "PGRST205") and ensuring faster subsequent failures after warmup.