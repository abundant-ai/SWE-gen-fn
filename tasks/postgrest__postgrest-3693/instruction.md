When using PostgREST’s spread embedding syntax (the `...` operator for embedded resources), aggregate functions inside the embedded/spread portion produce incorrect results or fail to be planned correctly.

A common scenario is requesting a parent resource with an embedded child relationship, spreading the embedded fields into the parent object, and also asking for aggregates (especially `count()` and field aggregates like `sum()`, `avg()`, etc.) within that embedded context. In these cases PostgREST should generate a correct SQL query that returns the expected aggregate values and grouping, but currently the combination of “aggregate in embedded resource” + “spread embedding” leads to wrong output (missing fields, incorrect grouping, or query errors).

The system should support these behaviors consistently across top-level and embedded selections:

- `count()` without an explicit field should return the number of rows in the relevant scope.
- `count()` should support aliasing (e.g. `cnt:count()`) and casting (e.g. `count()::text`).
- When selecting both aggregated and non-aggregated fields together, results must be grouped by all selected non-aggregated fields (including when those fields originate from a spread embedded resource).
- Backwards-compatible `count` as a pseudo-column selection must continue to work, including inside embedded resources.

Example requests that must work (illustrative):

- A request that selects only `count()` should return a single JSON object with the total count for that resource.
- A request that selects an aggregate plus one or more non-aggregated columns should return multiple rows grouped by those columns, and ordering should work on those grouped columns.
- A request that embeds a related resource and requests `count`/`count()` within that embedded selection should return the correct embedded aggregate.
- The same kinds of aggregate selections must work when the embedded resource is spread into the parent (using `...`), producing correct JSON keys and correct aggregate values.

Fix the query building/planning so that aggregates inside spread embedded resources are properly recognized as aggregates, included in the correct SELECT list, and generate the correct GROUP BY behavior without breaking existing aggregate support outside of spread embedding.