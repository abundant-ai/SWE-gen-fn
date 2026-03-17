PostgREST currently responds with `404 Not Found` when a client uses an HTTP method that PostgREST does not support (for example `CONNECT`, `TRACE`, or any unknown verb like `OTHER`). This is not HTTP-compliant: the server should instead respond with `405 Method Not Allowed` for unsupported HTTP verbs.

When a request is made to any path (including `/`) using an unsupported verb, the response must:

- Use HTTP status `405 Method Not Allowed` (not 404).
- Return a JSON error body with the exact message format:

```json
{"message":"Unsupported HTTP verb: <VERB>"}
```

Where `<VERB>` is the exact method token received (e.g. `CONNECT`, `TRACE`, `OTHER`).

Examples that must work:

- `CONNECT /` must respond with status `405` and body `{"message":"Unsupported HTTP verb: CONNECT"}`.
- `TRACE /` must respond with status `405` and body `{"message":"Unsupported HTTP verb: TRACE"}`.
- A request with method `OTHER` to `/` must respond with status `405` and body `{"message":"Unsupported HTTP verb: OTHER"}`.

This change should be applied at the point where PostgREST classifies/decodes the incoming HTTP method into its internal request/route representation, so that unsupported verbs are detected early and mapped to a 405 response consistently across endpoints (root, tables, RPC, etc.). The previous behavior of treating these as “not found” must be eliminated.

Additionally, remove the previously “impossible” error branch associated with the old unsupported-verb handling (i.e., the code should no longer keep an unreachable/unused error case for `UnsupportedVerb` if it cannot occur after the refactor).