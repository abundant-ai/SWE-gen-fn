When performing a mutation request (INSERT/UPDATE/DELETE) that returns a representation (via the usual “returning representation” behavior), the response body is not being correctly filtered when the request also includes complex boolean filters using `or`/`and` query parameters (including nested forms like `not.or`, `or=(and(...),and(...))`, and embedded-resource boolean filters such as `child_entities.or=(...)` or deeper embedded levels).

The expected behavior is that the returned JSON representation from a mutation is filtered consistently with the same boolean logic semantics used for GET requests: only rows that satisfy the full filter expression (including `or`/`and`, `not`, and combinations with traditional filters like `name=eq...`) should appear in the returned representation. The filtering must apply correctly at embedded levels too (e.g., boolean logic on `child_entities` or `child_entities.grandchild_entities`), so that embedded arrays are filtered by their corresponding embedded `or`/`and` conditions.

Currently, when these boolean filters are present on a mutation request that returns rows, the representation filtering is incorrect: rows (or embedded rows) that should be excluded by the `or`/`and` conditions can still appear, or the boolean expression is effectively ignored/misapplied in the mutation response even though the same expression works properly for GET. This leads to mutation responses that do not match the filter semantics the user asked for.

Fix the mutation response generation so that `or`/`and` boolean logic (including nested `not` and combinations with regular filters) is applied to the returned representation in the same way it is applied for GET, including for embedded resource levels. Reproduction examples that must behave correctly include query patterns like:

- `... ?or=(id.eq.1,id.eq.2)&select=id`
- `... ?not.or=(id.eq.1,id.eq.2)&select=id`
- `... ?or=(id.eq.1,id.eq.2)&name=eq.entity 1&select=id`
- `... ?or=(and(name.eq.entity 2,id.eq.2),and(name.eq.entity 1,id.eq.1))&select=id`
- embedded: `... ?child_entities.or=(id.eq.1,name.eq.child entity 2)&select=id,child_entities(id)`
- deeper embedded: `... ?child_entities.grandchild_entities.or=(id.eq.1,id.eq.2)&select=id,child_entities(id,grandchild_entities(id))`

After the fix, mutation responses returning representations must match the same filtering semantics and results that users already get from GET with the same filters and select/embedding structure.