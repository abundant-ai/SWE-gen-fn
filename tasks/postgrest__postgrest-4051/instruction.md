When PostgREST validates JWTs signed with asymmetric keys (e.g., RS256) using a JWK/JWKS-like JSON provided via `PGRST_JWT_SECRET`, failures in key selection currently produce an unhelpful error message. In particular, when the JWT header contains a `kid` that does not match any key available in the configured JWK set (or when the available key(s) are of an incompatible type for the JWT `alg`), PostgREST can return the generic message:

`No suitable key or wrong key type`

This makes it difficult to diagnose configuration problems such as “JWT and JWK key ids must match”.

Improve the error details for the PGRST301 authentication error so that, when JWT verification fails due to key selection issues, the response clearly indicates what went wrong. The error should distinguish at least these scenarios:

- The JWT header specifies a `kid`, but no configured JWK has a matching `kid`.
- A key was found (or keys exist) but none are usable for the JWT’s algorithm/key type (e.g., RS256 token but only non-RSA keys are available, or otherwise incompatible key material).

Expected behavior: for requests with an invalid/unsatisfiable JWT due to the above key id/type mismatch situations, the server responds with PGRST301 and an error message that includes actionable detail (e.g., indicating a `kid` mismatch or incompatible key type/algorithm), rather than only the generic “No suitable key or wrong key type”.

Reproduction example:
- Configure `PGRST_JWT_SECRET` with an RSA JWK JSON (fields like `kty: RSA`, `n`, `e`, `alg: RS256`).
- Send a request using a JWT signed with RS256 whose header `kid` does not match the configured JWK’s `kid` (or where the configured key set cannot satisfy the JWT’s algorithm).

Actual behavior: PostgREST returns PGRST301 with the generic message.

Implement the improved PGRST301 error detail so operators can immediately identify whether the problem is a `kid` mismatch or an incompatible key type/algorithm during JWT verification.