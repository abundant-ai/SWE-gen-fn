JWT verification/parsing is performed on every request, which is expensive when using asymmetric JWT signatures (e.g., RS256/ES256). Add a time-limited cache for JWT validation/parsing results so that repeated requests using the same JWT do not re-run the cryptographic verification each time.

Introduce a configuration option named `jwt-cache-max-lifetime` (integer, seconds). When `jwt-cache-max-lifetime = 0`, caching must be disabled (current behavior: validate/parse every request). When set to a positive number, PostgREST should cache the result of validating and parsing a JWT and reuse it for subsequent requests that present the exact same token, until the cached entry expires.

Expected behavior:
- With caching enabled, if multiple requests use the same `Authorization: Bearer <token>` value, PostgREST should reuse the previously validated/parsed JWT claims instead of re-verifying the signature each time.
- Cached entries must not live longer than `jwt-cache-max-lifetime` seconds.
- Cached entries must also not outlive the JWT’s own validity; if a token becomes invalid due to time-based claims (e.g., expiration), the cache must not cause it to be accepted beyond its valid period.
- Invalid tokens must not be accepted due to caching. If a token is invalid (bad signature, malformed, wrong audience, etc.), it should remain invalid; caching must not turn an invalid token into a valid one.
- The new config option must be recognized in configuration output/printing and have a default value of `0` when not set.

Users should be able to set, for example:
- `jwt-cache-max-lifetime = 86400` to allow up to one day of caching for repeated JWTs, while still respecting each token’s own expiration.

Currently, `jwt-cache-max-lifetime` is missing/ignored, and JWT validation is redone for every request. Implement the caching behavior and ensure the new configuration key is properly parsed, defaulted, and reflected in the server’s effective configuration.