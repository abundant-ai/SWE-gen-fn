When a client requests a custom media type (via the Accept header) that is implemented using an aggregate over rows (e.g. TWKB, generic anyelement-based handlers like CSV), GET requests fail whenever the request includes a `select=` parameter that is not `*`.

The failure happens because PostgREST builds the aggregate query by casting each selected row to the underlying table composite type (e.g. `twkb_agg(_postgrest_t::"schema"."table")`). That cast only works when the row being aggregated has exactly the same columns, in the same order, as the table type. As soon as the client selects a subset of columns, reorders columns, or includes computed columns, the cast becomes invalid and the request cannot be served using the custom media handler.

This breaks scenarios like implementing a generic handler with an aggregate defined as `AGGREGATE ... (anyelement)` (for example, producing `text/csv` from arbitrary row shapes). Users should be able to request a custom media type while also using `select=` to shape the output rows.

Expected behavior:
- Requests with a custom media type handler should work with `select=` projections (subset of columns, reordered columns, and computed columns), as long as the handler’s aggregate can accept the projected row type.
- PostgREST should only cast the row to the original table composite type in the one case where that cast is guaranteed to be correct: when the selection is exactly `*` (either implicitly because `select=` is omitted, or explicitly `select=*`).

Actual behavior:
- For custom media type handlers backed by table-specific aggregates or generic `anyelement` aggregates, adding `select=` (anything other than `*`) causes the generated SQL to cast the projected row to the table type, which fails and prevents the custom media type response from being produced.

Implement the fix so that the table-type cast is avoided whenever the client’s selection is not exactly `*`, while preserving the existing behavior for implicit/explicit `select=*` so table-specific aggregates can still be resolved correctly by argument type when appropriate.