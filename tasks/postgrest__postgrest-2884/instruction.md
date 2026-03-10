PostgREST currently accepts HTTP `Prefer` request headers (RFC 7240) such as `return=representation`, `return=minimal`, and `return=headers-only`, but it does not consistently communicate back to clients which preferences were actually honored. Clients therefore cannot reliably determine whether the server applied a given preference without inferring it from the response body/status.

Implement support for returning a `Preference-Applied` response header whenever PostgREST applies any of these `Prefer: return=...` values. The response must include the applied `return` preference value (e.g., `return=representation` or `return=minimal`). When multiple preferences are applied for a request (for example `resolution=merge-duplicates` together with `return=representation`), `Preference-Applied` must list all applied preferences in a single header value as a comma-separated list in a stable, predictable order (e.g., `resolution=merge-duplicates, return=representation`).

Required behaviors:

- For mutation requests (e.g., DELETE/PATCH/POST) made with `Prefer: return=representation`, when the server returns a representation body, the response must include `Preference-Applied: return=representation`.
- For mutation requests made with `Prefer: return=minimal`, when the server returns an empty body (commonly a 204 response with no `Content-Type`), the response must include `Preference-Applied: return=minimal`.
- For requests that include multiple `Prefer` directives that PostgREST honors (e.g., `Prefer: resolution=merge-duplicates` and `Prefer: return=representation`), the response must include a single `Preference-Applied` header enumerating all honored preferences (example: `Preference-Applied: resolution=merge-duplicates, return=representation`).
- If a request does not include a `Prefer: return=...` directive, or if the server does not apply it, `Preference-Applied` must not claim it was applied.

The implementation should ensure this header is produced consistently across supported endpoints where `Prefer` handling already exists, and it must not break existing semantics such as omitting `Content-Type` for 204 minimal responses.