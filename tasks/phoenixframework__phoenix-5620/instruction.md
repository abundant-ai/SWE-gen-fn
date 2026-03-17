Phoenix endpoints need a standard way to expose runtime server details to the underlying HTTP server adapter and external tooling. Currently, there is no public callback on `Phoenix.Endpoint` for retrieving server information, making it difficult for servers/adapters to query things like the configured scheme/host/port and other endpoint-derived values in a consistent way.

Implement a new callback `c:Phoenix.Endpoint.server_info/1` on `Phoenix.Endpoint` and provide a default implementation such that calling `MyAppWeb.Endpoint.server_info/1` returns a structured description of the endpoint’s server-related configuration.

The callback should accept a single argument that indicates which listener is being queried (for example, HTTP vs HTTPS), and it must return information consistent with the endpoint’s resolved configuration. In particular, endpoint configuration may use system-tuple values (for example `{:system, "ENDPOINT_TEST_HOST"}`), and `server_info/1` must resolve those values to their actual runtime values before returning them.

`server_info/1` must correctly reflect changes applied at runtime via `config_change/2`. For example, if the endpoint’s `url` or `static_url` port is changed through `config_change/2`, subsequent calls to `server_info/1` must return values reflecting the updated port(s), without requiring a restart.

Expected behavior:
- `MyEndpoint.server_info(:http)` and `MyEndpoint.server_info(:https)` (or the supported listener identifiers used by the endpoint) return non-error results describing the server configuration for that listener.
- Returned information uses the endpoint’s current resolved URL configuration (including `host`, `port`, `scheme`, and `path` where applicable), and respects settings like `force_ssl` that influence the externally visible scheme.
- Any configuration values provided via `{:system, VAR}` are resolved using the current environment value of `VAR`.
- After calling `MyEndpoint.config_change([{MyEndpoint, new_config}], [])`, calling `server_info/1` returns information based on `new_config`.

Actual behavior to fix:
- There is no `server_info/1` callback/function available on endpoints, or it does not return correctly resolved/updated runtime server information needed by server adapters and downstream applications.