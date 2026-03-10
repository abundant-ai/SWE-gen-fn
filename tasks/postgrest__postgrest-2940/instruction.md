PostgREST currently accepts any unrecognized `Prefer` value and silently ignores it. This makes it hard for clients to detect whether a deployed server actually supports a given preference. Additionally, the `Preference-Applied` response header is inconsistent: it can claim a preference was applied when it wasn’t (e.g., `tx=commit` appears even when the transaction did not commit), and it can omit preferences that were applied (e.g., `count=exact` not appearing).

When a client sends a request like:

```bash
curl -D - 'http://localhost:3000/projects' -H 'Prefer: anything'
```

the request is currently accepted and returns `200 OK`, even though `anything` is not a recognized preference.

PostgREST must support RFC7240 `Prefer: handling=strict` and `Prefer: handling=lenient` semantics:

- If the request includes `Prefer: handling=strict` and also includes any unrecognized/unsupported `Prefer` tokens, the server must reject the request with `400 Bad Request`.
  Example:
  
  ```bash
  curl -D - 'http://localhost:3000/projects' -H 'Prefer: handling=strict; anything'
  ```
  
  must return `HTTP/1.1 400 Bad Request`.

- If the request includes `Prefer: handling=lenient` (or does not specify a handling mode), unrecognized preferences should continue to be accepted and ignored (existing behavior).

Separately, `Preference-Applied` must accurately reflect only the preferences that were actually applied to produce the response:

- If the client sends `Prefer: tx=commit` but the transaction does not commit (for example when the server is configured to end transactions with rollback while allowing override, and the request ultimately fails), the response must not include `Preference-Applied: tx=commit`. Today it can appear even when the response is an error such as:

```json
{"code":"PGRST116","details":"The result contains 2 rows","hint":null,"message":"JSON object requested, multiple (or no) rows returned"}
```

- If the client requests an exact count using `Prefer: count=exact`, and the response includes an exact count (e.g., via a `Content-Range` indicating a concrete total like `*/1`), then `Preference-Applied` must include `count=exact` along with other applied preferences. For example, a request like:

```bash
curl -D - -H 'Content-Type: application/json' \
  -H 'Prefer: count=exact, return=representation' \
  'http://localhost:3000/projects' \
  -d '{"id":180,"name":"new"}'
```

should return `Preference-Applied` including both preferences, e.g. `return=representation, count=exact` (ordering may match server conventions), rather than omitting `count=exact`.

In general, any response (including successful responses like 200/201/204 and error responses like 4xx) should only echo back preferences in `Preference-Applied` that were actually honored for that response. Unsupported preferences must never appear in `Preference-Applied`, and in strict handling mode unsupported preferences must cause a 400 rejection instead of being ignored.