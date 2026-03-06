PostgREST does not correctly validate JWT audience values that contain a ':' character. Per RFC 7519, an "aud" value is a StringOrURI, which means arbitrary strings are allowed, but if the value contains a ':', it MUST be a valid URI per RFC 3986. Currently, PostgREST allows invalid URI strings containing ':' to pass validation, so the server can start (or accept tokens) even when the configured audience or token audience is malformed.

Reproduction example (config validation): set the environment variable `PGRST_JWT_AUD` to a value containing ':' that is not a valid RFC 3986 URI, such as:

`PGRST_JWT_AUD='http://%%localhorst.invalid'`

Expected behavior: PostgREST should treat this as invalid configuration and fail fast during startup (including when invoked via `--dump-config`), returning a non-zero exit code.

Actual behavior: PostgREST accepts the value and continues running/printing config successfully.

This same RFC requirement must also be enforced for JWTs presented to PostgREST: when validating an incoming JWT, the `aud` claim may be a single string or an array of strings. For each audience value, if it contains a ':', it must parse as a valid RFC 3986 URI; otherwise token validation should fail (i.e., the request should be rejected as an invalid/unauthorized JWT). Valid audience strings without ':' must continue to be accepted as plain strings, and valid URI audiences containing ':' must continue to be accepted.

Implement RFC-compliant validation for both:

1) the configured `jwt-aud` value (e.g., via `PGRST_JWT_AUD`), causing startup/config parsing to error on invalid URI-like values, and
2) the JWT `aud` claim during authentication, rejecting tokens whose `aud` entries violate the StringOrURI rule.

The validation should be case-sensitive string comparison semantics (no canonicalization), and should only apply URI parsing/validation when ':' is present in the audience value.