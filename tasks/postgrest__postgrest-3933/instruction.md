JWT-related authentication failures currently surface confusing or incorrect errors, and some invalid inputs incorrectly fall through to the database layer.

When a client sends an `Authorization: Bearer <token>` header, PostgREST should validate the JWT early and return clear, user-facing authentication errors. Instead, several cases either expose internal/low-level errors (e.g., by stringifying internal exceptions), or they proceed to execute the request against the database and fail with unrelated SQL permission errors.

The following problems need to be fixed:

1) Empty JWT in the Authorization header is not rejected early.

If a request includes an empty bearer token (note the trailing space):

```bash
curl http://localhost:3000/authors_only -H "Authorization: Bearer "
```

the request currently reaches the database and can fail with a PostgreSQL error like:

```json
{"code":"42501","details":null,"hint":null,"message":"permission denied for table authors_only"}
```

This is misleading (the real problem is an invalid/empty JWT), and it can also poison caches when response caching is enabled. Expected behavior: the request should be rejected as an authentication error before any database interaction, with an appropriate `WWW-Authenticate: Bearer` challenge header.

2) JWT verification failures expose internal/unfriendly error strings.

For invalid JWTs (bad formatting, invalid signature, wrong audience, expired token, invalid claims, etc.), PostgREST currently exposes internal error text directly to clients. Expected behavior: return improved, user-friendly error messages for JWT failures rather than raw internal `show`/stringified errors.

These JWT failure responses should be consistent and clearly indicate the authentication problem (JWT is missing/empty/malformed/failed verification), and they should not leak internal implementation details.

3) Misleading "Server lacks JWT secret" behavior.

Users can encounter a response like:

```json
{ "message": "Server lacks JWT secret" }
```

in situations where JWT authentication is attempted. The system should provide clearer diagnostics for JWT secret configuration/availability problems and ensure that JWT-related errors include actionable details. In particular, when JWT authentication is used but the server cannot verify tokens due to missing/unavailable secret configuration, the error reported to the client should be accurate and informative.

Implement improved JWT error handling so that:
- Empty bearer tokens are treated as invalid JWTs and rejected before hitting the database.
- Invalid JWTs produce improved, user-facing error messages (not internal/raw error strings).
- JWT secret/configuration problems produce accurate, clearer error details.
- Authentication failures include the proper `WWW-Authenticate: Bearer` header where applicable.
