When JWT caching is enabled, PostgREST continues to accept previously-seen JWTs even after `jwt-secret` is changed via a configuration reload. This is incorrect: after the secret changes, any JWTs that were validated (or cached as valid) under the old secret must no longer be accepted.

Reproduction scenario:
1) Start PostgREST with JWT auth enabled, a valid `jwt-secret`, and JWT caching enabled (e.g., set a non-zero cache max lifetime).
2) Send a request with an Authorization Bearer JWT signed using the current secret; it succeeds (e.g., accessing a role-protected endpoint returns HTTP 200).
3) Reload configuration and change `jwt-secret` to a different value.
4) Send the same request again using the old JWT.

Expected behavior: the request should now be rejected as an invalid JWT because it is signed with the old secret (e.g., return an authentication error such as HTTP 401).

Actual behavior: the request is still accepted because the JWT validation result is served from the cache even though the `jwt-secret` has changed.

Fix requirement:
- Ensure that changing `jwt-secret` during a config reload invalidates any cached JWT validation state that depended on the previous secret.
- After a reload with a different `jwt-secret`, a JWT signed with the old secret must not authenticate successfully, even if it was previously cached as valid.
- A JWT signed with the new secret should authenticate successfully after the reload.

This should work reliably when the JWT secret is supplied directly or loaded from an external source (e.g., a file/stdin), and it must apply specifically on config reload (not only on process restart).