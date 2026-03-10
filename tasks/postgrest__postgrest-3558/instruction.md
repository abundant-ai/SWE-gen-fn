PostgREST currently has an `admin-server-port` setting for running the admin HTTP server, but there is no separate host binding for it. As a result, users cannot bind the admin server to a different interface than the main server host; the admin server effectively shares `server-host` (or otherwise cannot be configured independently), which prevents common setups like exposing the main API on `0.0.0.0` while keeping the admin endpoint on `127.0.0.1`.

Introduce an optional configuration setting named `admin-server-host`.

Behavior requirements:
- The config loader must recognize `admin-server-host` as a valid setting.
- If `admin-server-host` is explicitly provided, the admin server must bind to that host.
- If `admin-server-host` is not provided, it must default/fallback to the configured `server-host` value (including when `server-host` is set to IPv4/IPv6 wildcard values).
- The value must round-trip through the configuration rendering/printing the same way other host settings do (i.e., appears in the normalized/printed configuration output with the resolved value).
- Existing behavior for `admin-server-port` remains unchanged; only add host selection for the admin server.

Example scenario:
- With `server-host = "0.0.0.0"`, `server-port = 3000`, `admin-server-port = 3001`, and `admin-server-host = "127.0.0.1"`, the main server should listen on `0.0.0.0:3000` while the admin server listens on `127.0.0.1:3001`.
- With `server-host = "0.0.0.0"` and `admin-server-port = 3001` but no `admin-server-host` specified, the admin server should listen on `0.0.0.0:3001`.

If `admin-server-host` is present but invalid for the host type accepted by `server-host`, configuration loading should fail with a clear parse/validation error consistent with other invalid host settings.