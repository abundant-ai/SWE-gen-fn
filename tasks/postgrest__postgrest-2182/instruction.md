The admin health-check endpoints on the admin server (e.g. `GET /live` and `GET /ready`) incorrectly return failure responses when PostgREST is configured to listen on special host values like `*` (all interfaces) or `!4`/`!6` (IPv4/IPv6-only). In these configurations, PostgREST can be fully operational and serving normal API requests on the main server port, but the admin health checks still respond with `503 Service Unavailable`.

This happens because the health-check logic attempts to connect to the main server using the configured `server-host` value as if it were a normal resolvable hostname. For example, when `server-host` is set to `!4`, the health-check connection attempt can fail with an error like:

`Network.Socket.getAddrInfo ... host name: Just "!4" ... does not exist (Name or service not known)`

When `server-host` is set to `*`, the health check can fail with a connection error (e.g. `Connection refused`) even though the service is reachable via `localhost`/`127.0.0.1`.

Expected behavior: if PostgREST is running and the main HTTP server is accepting connections, then requesting `http://<admin-host>:<admin-port>/live` should return `200 OK` (and similarly for `/ready` when the instance is ready). These endpoints must work regardless of whether `server-host` is set to a normal hostname (like `localhost`) or to special listen values (`*`, `!4`, `!6`).

Actual behavior: with special `server-host` values, `curl -I "http://localhost:<admin-port>/live"` returns `HTTP/1.1 503 Service Unavailable` even though requests to the main server port succeed.

Fix the admin health-check implementation so that it correctly determines a connectable address for probing the main server when `server-host` is a special listen value. After the fix, `/live` and `/ready` should return success whenever the main server is actually reachable, including when the service is configured with `server-host = "*"`, `"!4"`, or `"!6"`.