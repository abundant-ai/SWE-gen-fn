PostgREST currently accepts a `jwt-secret` that is shorter than 32 characters (e.g. `jwt-secret = "secret"`), but this leads to confusing authentication failures later (commonly `401` with `WWW-Authenticate: Bearer error="invalid_token", error_description="JWSError JWSInvalidSignature"` / body `{ "message": "JWSError JWSInvalidSignature" }`). This often happens when users follow older tutorials or examples and configure a short secret.

The server should detect this misconfiguration at configuration/boot time and provide a clear message indicating that the JWT secret is too short and must be at least 32 characters long. This validation must apply to the decoded value when `jwt-secret-is-base64` is enabled (i.e., if the secret is provided as base64, validate the length of the decoded secret, not the base64 text itself).

Concretely:

- When parsing/validating JWT configuration via `parseSecret` (used to build `AppConfig`), if a JWT secret is present but is shorter than 32 characters/bytes, PostgREST should fail fast with an explicit error message about the minimum length requirement.
- The error should be specific enough to guide the user to fix the config (e.g., “JWT secret must be at least 32 characters long” or equivalent wording) rather than allowing the server to start and later produce `JWSError JWSInvalidSignature`.
- This should not change behavior for valid secrets (>= 32), including base64 secrets whose decoded value meets the minimum.

Example of a problematic configuration that should be rejected with the clearer message:

```ini
db-uri = "postgres://postgres:..."
db-schema = "api"
db-anon-role = "web_anon"
jwt-secret = "secret"
```

Expected behavior: server reports a clear configuration error about `jwt-secret` being too short (minimum 32) and does not proceed as if JWT verification were correctly configured.

Actual behavior (current): server starts, but authenticated requests can fail with `401` and `JWSError JWSInvalidSignature`, which does not explain that the root cause is an undersized `jwt-secret`.