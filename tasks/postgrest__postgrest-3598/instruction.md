PostgREST’s JWT verification needs to be updated to use the `jose-jwt` library while preserving (and correctly enforcing) the JWT validation behavior that users rely on.

Currently, after switching JWT verification away from `hs-jose`, token verification can succeed or fail incorrectly because `jose-jwt` only verifies the signature/key but does not automatically enforce standard claims validation. PostgREST must validate these claims itself:

- `exp`: reject expired tokens
- `nbf`: reject tokens that are not yet valid
- `iat`: reject tokens with an invalid issued-at time when applicable
- `aud`: when an audience is configured, reject tokens whose audience does not match

These validation failures must result in the same kind of HTTP-level behavior and message semantics that PostgREST exposed before the refactor: invalid JWTs should produce a 401 response and return a JSON error whose `message` reflects the JWT verification/validation failure (for example, signature failures should still produce the same error message string that users currently see for invalid signatures).

In addition, JWT caching and Server-Timing behavior must remain correct and stable. With caching enabled, repeated requests using the same JWT should avoid repeated JWT parsing/verification work. With caching disabled, repeated requests should not become faster due to any unintended caching, and the Server-Timing metric for JWT-related work should not decrease across repeated requests when caching is turned off.

Reproduction examples that must work:

1) When a request uses an `Authorization: Bearer <jwt>` header signed with the wrong secret, the response must be `401`, and the returned JSON must include a `message` indicating an invalid signature (e.g. `JWSError JWSInvalidSignature`).

2) When `PGRST_JWT_AUD` is set (for example to `io tests`) and the token’s `aud` claim is missing or does not match, the request must be rejected as an invalid JWT with the appropriate 401 error JSON.

3) When the token contains time-based claims (`exp`, `nbf`, `iat`) that make the token invalid relative to the current time, it must be rejected as an invalid JWT with the appropriate 401 error JSON.

4) JWT caching must measurably avoid repeated verification work when enabled, and must not affect repeated-request timing when disabled; the Server-Timing value for JWT processing must not decrease across repeated requests when caching is disabled.

The fix should ensure PostgREST performs full JWT validation (signature + required claim checks) with `jose-jwt`, preserves the externally visible error messages/status codes for JWT failures, and restores correct cache/timing behavior for both caching enabled and disabled modes.