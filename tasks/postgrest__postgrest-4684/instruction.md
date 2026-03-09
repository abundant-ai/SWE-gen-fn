When PostgREST handles requests to non-existent resources (tables, functions, and embedding relationships), it generates an error response (commonly with code `PGRST205`) that may include a "hint" suggesting a similarly named object. Currently, the similarity threshold used to decide whether to show a hint is too permissive, causing PostgREST to suggest unrelated real object names even when the requested name is very different (e.g., requesting `clientsxxxxxxxxxxxxxx` can still return a hint suggesting `test.clients`). This can leak table/function names and enable schema enumeration even when `openapi-mode=follow-privileges` is enabled.

Reproduction examples that currently may leak information:

- `GET /users?select=*` can return a hint like `Perhaps you meant the table 'public.markers'` even though `users` doesn’t exist.
- `GET /employee_locations?select=*` can return `Perhaps you meant the table 'public.employees'`.
- `GET /clientsxxxxxxxxxxxxxx` can return `Perhaps you meant the table 'test.clients'`.

Expected behavior: PostgREST should only return a hint when the requested identifier is a close typo of an existing object. For non-existent names that are not close (including long strings with many extra characters), the response must have `"hint": null`.

Implement a stricter maximum fuzzy distance comparable to PostgreSQL’s behavior (effectively limiting suggestions to very small edit distances, e.g. distance <= 3). As a result, requests like `GET /fakefake` should return a 404 with an error body containing `"code":"PGRST205"` and `"hint": null` (and still include the standard message like `Could not find the table 'test.fakefake' in the schema cache`). The same stricter hinting behavior should apply consistently to table-name hints, function-name hints (RPC), and embedding-related hints, so none of them leak object names for distant matches.