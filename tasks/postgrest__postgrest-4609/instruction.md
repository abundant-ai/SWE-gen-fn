PostgREST responses currently do not include a `Vary` header, even though the representation returned by the server can change based on request headers such as `Accept` (content negotiation) and `Range` (partial content). This causes incorrect behavior for HTTP caches and intermediaries, which may reuse a cached response for requests with different `Accept` or `Range` headers.

When a client requests a resource and the server may return different representations depending on request headers, the response must include an appropriate `Vary` header. In particular:

- Responses whose output can change based on the `Accept` header must include `Vary: Accept`.
- Responses whose output can change based on the `Range` header (e.g., returning partial content) must include `Vary: Range`.
- If both apply, the `Vary` header must reflect both (e.g., `Vary: Accept, Range`), using standard HTTP header list formatting.

This should apply consistently across the main REST endpoints and RPC endpoints so that a `GET`/`HEAD` to the same URL is correctly cache-keyed when `Accept` differs (for example requesting JSON vs another supported representation) and when `Range` is used.

Additionally, HEAD handling must remain correct: a `HEAD` request should return the same headers that an equivalent `GET` would return (including `Vary`), while not including a response body.

Example scenario that should work correctly:

```http
GET /projects HTTP/1.1
Accept: application/json

# Response must include: Vary: Accept
```

```http
GET /projects HTTP/1.1
Range: 0-1

# Response must include: Vary: Range
```

```http
HEAD /projects HTTP/1.1
Accept: application/json
Range: 0-1

# Response must include: Vary: Accept, Range
# and must not include a message body
```

Expected behavior: any response whose representation can change due to `Accept` and/or `Range` includes the correct `Vary` header so caches do not serve the wrong variant.

Actual behavior: responses omit `Vary`, making caches treat variants as the same resource and potentially serve an incorrect cached representation.