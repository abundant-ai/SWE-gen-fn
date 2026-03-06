The admin server currently exposes a `/config` HTTP endpoint that returns the running configuration over the network. This response can include sensitive values (for example credentials embedded in `db-uri`), which makes it easy to accidentally leak secrets when the admin server is exposed.

Change the admin server behavior so that the `/config` endpoint is no longer available. Requests to `/config` on the admin server should not return configuration data anymore and should respond as an unknown/unsupported endpoint (for example an HTTP 404).

Additionally, the configuration option that previously controlled whether `/config` was enabled (named `admin-server-config-enabled`) should no longer exist. If a user provides this option (via environment variable, config file, or any supported configuration source), PostgREST should not accept it as a valid setting.

The goal is to ensure that PostgREST cannot expose its full configuration (and thus secrets) via an admin HTTP endpoint, even if the admin server is inadvertently made reachable.