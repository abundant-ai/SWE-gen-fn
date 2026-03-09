PostgREST currently leaks schema/function information in client-facing error responses when a request targets an RPC function in an exposed schema that the current role does not have USAGE permission for. In these cases, instead of consistently returning a permission error, PostgREST may return a “function not found in schema cache” style error that includes details and hints (including suggested function names), which can disclose information about objects inside a protected schema.

Reproduction examples (role lacks permission on schema `admin`):
- Calling a slightly misspelled function like `admin.custom_function2` returns an error with code `PGRST202` and includes `details` describing the function search and a `hint` suggesting `admin.custom_function`.
- Calling a completely non-existent function like `admin.missing_function` also returns `PGRST202` with function-search `details`.
- Calling an existing function with wrong parameters (e.g., a function that requires 1 argument but none is passed) still returns `PGRST202` with similar `details`.
- Calling the correct function name `admin.custom_function` returns a PostgreSQL permission error:
  - `code`: `42501`
  - `message`: `permission denied for schema admin`
  - `details`: `null`
  - `hint`: `null`

Expected behavior: for security and consistency, all attempts to access RPC functions in a schema the role cannot use should yield the same permission-denied response as the successful name lookup case, regardless of whether the function exists, is misspelled, or is called with incorrect parameters. Concretely, these cases should return the permission error:

```json
{
  "code": "42501",
  "details": null,
  "hint": null,
  "message": "permission denied for schema admin"
}
```

Additionally, PostgREST should support a new configuration setting named `client-error-verbosity` that controls how much information PostgREST includes in client-side HTTP error responses. It must support at least these values:
- `verbose`: current/full client error payloads (including `details` and `hint` when available)
- `minimal`: sanitize client error payloads to reduce information disclosure; lower verbosity should remove/nullify `details` and `hint` in JSON error bodies, while still returning appropriate error codes and a safe `message`.

This configuration must only affect client-facing HTTP responses; server-side logs should not be made less verbose by this setting.

The change should also address related information disclosure issues where PostgREST error messages enumerate schemas a user cannot access (e.g., when an invalid `Accept-Profile` is provided, the returned message should not list schemas for which the current role lacks USAGE permission).