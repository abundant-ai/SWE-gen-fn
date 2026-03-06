When PostgREST is running with JWT authentication enabled, changing the JWT secret via a configuration reload can cause valid JWTs (signed with the newly configured secret) to be rejected until the server is restarted.

Reproduction scenario:
1) Start PostgREST with a JWT secret configured (including cases where the secret is sourced from a file path like "@/path/to/secret" or from stdin like "@/dev/stdin", and optionally using a base64-encoded secret when the corresponding flag is enabled).
2) Make an authenticated request with a JWT signed using the currently configured secret; it succeeds.
3) Trigger a config reload while also changing the configured JWT secret to a different value.
4) Make an authenticated request with a JWT signed using the new secret.

Expected behavior: After the config reload completes, JWT verification should immediately use the updated jwt-secret. Requests authenticated with tokens signed by the new secret should succeed (e.g., return HTTP 200 for an endpoint requiring an authenticated role), and tokens signed with the old secret should no longer be accepted.

Actual behavior: After the reload, PostgREST continues validating tokens using the previous secret (or a stale JWT validation state), causing tokens signed with the new secret to be rejected (typically as an authentication failure such as HTTP 401).

Fix required: Ensure that configuration reload fully refreshes the JWT verification configuration/state so that any update to the JWT secret (including secrets loaded from "@file" sources, stdin sources, and base64 secrets) takes effect immediately after reload, without requiring a process restart.