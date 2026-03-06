The admin HTTP server currently exposes a `/config` endpoint by default when the admin server is enabled. This endpoint can include sensitive values (for example credentials embedded in `db-uri`), so it should not be exposed over the network unless explicitly opted into.

Change the admin server behavior so that `/config` is disabled by default and is only served when an explicit configuration flag is enabled.

A new configuration setting named `admin-server-config-enabled` must be supported. Expected behavior:

- Default behavior: `admin-server-config-enabled` is `false` unless the user explicitly sets it to `true`.
- When `admin-server-port` is set (admin server enabled) but `admin-server-config-enabled` is unset or `false`, requests to the admin server’s `/config` endpoint must not return the configuration payload. It should behave as a non-existent/disabled endpoint (for example returning 404).
- When `admin-server-config-enabled=true`, the admin server’s `/config` endpoint should be available and return the configuration as before.

The configuration system must correctly parse and round-trip this setting the same way as other boolean settings (e.g., accepting boolean values from supported config sources, showing the correct default, and including it in generated/expected configuration output).