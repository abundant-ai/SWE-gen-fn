PostgREST’s OpenAPI output at the root endpoint ("/") currently always follows the authenticated role’s privileges when generating the OpenAPI spec. This makes it difficult for tooling (e.g., dashboards/clients) to fetch complete schema information unless they provide a high-privileged JWT, because tables/functions not accessible to the current role are omitted from the OpenAPI document.

Add support for a new configuration option named `openapi-mode` that controls how the OpenAPI spec is produced and whether it is available at all.

The server must support three modes:

1) `openapi-mode = "follow-acl"` (default)

When requesting `GET /` with `Accept: application/openapi+json`, the returned OpenAPI document must include only the objects the JWT role is allowed to access (current behavior). This is the default when the option is not set.

2) `openapi-mode = "ignore-acl"`

When requesting `GET /` with `Accept: application/openapi+json`, the OpenAPI document must be generated without filtering by the JWT role’s privileges. In this mode the OpenAPI output should include privileged tables and privileged RPC functions even if the requesting role does not have permission to access them. For example, the OpenAPI spec should still include endpoints like:

- `POST /authors_only` tagged with `"authors_only"`
- `POST /rpc/privileged_hello` tagged with `"(rpc) privileged_hello"`

Also, `HEAD /` with `Accept: application/openapi+json` should succeed with HTTP 200.

3) `openapi-mode = "disabled"`

OpenAPI output must be disabled. If a client requests `GET /` with `Accept: application/openapi+json`, the server must reject it with HTTP 415 (Unsupported Media Type) rather than returning a spec.

When OpenAPI is disabled, a normal JSON request to the root endpoint must behave as if the endpoint does not exist: `GET /` with `Accept: application/json` must return HTTP 404 (Not Found).

Configuration parsing and exposure requirements:

- `openapi-mode` must be recognized in config files and via environment variables using `PGRST_OPENAPI_MODE`.
- The effective configuration must round-trip through the server’s config output (i.e., when config is rendered/printed, it should show `openapi-mode = "follow-acl"` by default, and show `ignore-acl` when set).
- Invalid values for `openapi-mode` should be rejected as a configuration error (rather than silently defaulting).

The end result should allow users to choose between privilege-filtered OpenAPI output, an "all objects" OpenAPI output regardless of privileges, or completely disabling OpenAPI at the root endpoint with the HTTP behaviors described above.