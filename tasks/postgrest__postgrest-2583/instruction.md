When embedding related resources via the `select` query parameter, PostgREST returns an error if it cannot find a relationship between the requested parent and child in the schema cache (e.g., requesting `/x?select=a,y(*)`). The current error response includes a hint that often says to reload the schema cache (e.g., “If a new relationship was created, try reloading the schema cache.”). This hint is misleading in common cases where the real problem is a typo or a wrong table/embed name, and users waste time reloading the cache.

The error handling for “relationship not found” needs to be improved so that, when the requested relationship cannot be found, PostgREST provides suggestions based on fuzzy text search of existing table/relationship names. The goal is to guide the user to likely intended names (e.g., close matches to the parent or child resource) rather than implying that a schema cache reload is the likely fix.

Implement fuzzy suggestions in the relationship-discovery path used by resource embedding. When a request references a parent or child resource name that does not exist (or does not match any relationship candidates), the error response should include a `hint` that suggests the closest valid alternative name(s). The behavior should be:

- Suggest one side at a time (parent first, otherwise child): if the parent resource in the relationship lookup is not found, suggest the closest matching parent name and stop. If the parent exists but the child/embed target cannot be resolved, suggest the closest matching child/embed name.
- Suggestions should be based on fuzzy matching against available schema entities relevant to embedding (tables/views/relationships that the user could validly reference).
- The HTTP status and error code should remain consistent with the existing “relationship not found” error, but the `hint` text should change to include the fuzzy suggestion(s) instead of (or in preference to) the misleading schema-cache-reload advice.
- For cases where an embed is ambiguous because multiple relationships exist between the same two resources, the existing disambiguation behavior must remain unchanged: return `PGRST201` with status 300, include `details` describing each relationship, and provide a hint listing the explicit `!`-qualified embed alternatives.

Example of the problematic scenario to address:

Request:
`GET /x?select=a,y(*)`

Current response includes:
- `code`: `PGRST200`
- `message`: `Could not find a relationship between 'x' and 'y' in the schema cache`
- `hint`: includes “If a new relationship was created, try reloading the schema cache.”

Expected behavior:
- Still explain that no relationship was found, but the hint should primarily help correct the request by suggesting the most likely intended resource/embed name when `x` or `y` is close to an existing name.
- The hint should not misleadingly emphasize reloading the schema cache in cases where the issue is most likely a typo/mismatch.

This change should be reflected consistently anywhere PostgREST produces the relationship-not-found error for embedding, and the JSON error shape must remain valid (same top-level keys like `code`, `message`, `hint`, and `details` where applicable).