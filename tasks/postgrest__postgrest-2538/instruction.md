PATCH requests currently return `404 Not Found` (often with an empty JSON array body `[]`) when the request targets a valid resource but the UPDATE affects zero rows (e.g., because the filter matches nothing or RLS prevents the update). This is confusing, because the endpoint exists and the request is syntactically valid; it should not be treated as “resource not found” at the HTTP level.

Reproducible scenario:

```bash
http PATCH 'http://localhost:3000/projects?id=eq.33' \
  'Prefer: return=representation' \
  <<< '{"name":"any"}'
```

Current behavior: the server responds with `404 Not Found` and body `[]`.

Expected behavior:
- When PATCHing a real table/view endpoint and the request is valid but no rows are updated, the response must not be `404`.
- If `Prefer: return=representation` is set and zero rows are updated, respond with status `200 OK` and an empty JSON array body (`[]`).
- If no representation is requested (default behavior), the request should behave like a no-op update and respond successfully with `204 No Content` (no `Content-Type` header, empty body), even if zero rows were updated.
- Unknown endpoints (e.g. PATCH to a non-existent route/table) must still return `404 Not Found`.
- Invalid JSON payloads must still return `400` with the existing JSON error structure and code `PGRST102`.
- A `406 Not Acceptable` must still be returned when the client requests a single JSON object via an Accept header in a way that requires exactly one row but the update affects zero rows.

In short: change PATCH semantics so that “0 rows affected” is not treated as “not found”; it should return `200` with `[]` when returning a representation, and otherwise succeed with `204`.