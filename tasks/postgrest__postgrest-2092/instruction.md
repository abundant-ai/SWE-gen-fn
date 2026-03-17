PostgREST currently lacks a built-in, minimal health-check endpoint suitable for Kubernetes readiness/liveness probes without requiring a round-trip to the database. Implement a minimal health endpoint that is exposed only when an admin server port is configured.

When the `admin-server-port` configuration option is set, PostgREST must start an additional HTTP server on that port and expose a `GET /health` endpoint.

Behavior requirements:

1) Endpoint and responses
- `GET /health` must always respond with no response body.
- When PostgREST is healthy, it must respond with HTTP 200.
- When PostgREST is not healthy (e.g., database connection is down / PostgREST is in reconnecting state), it must respond with HTTP 503.

2) How health is determined
- If `db-channel-enabled = true` (default), the health check must be derived from the internal LISTEN/NOTIFY listener state (so that checking `/health` does not issue extra SQL queries).
- If `db-channel-enabled = false`, the health check must fall back to running a minimal query against the database (equivalent to `SELECT 1`) to determine whether the database is reachable.

3) Startup and concurrency expectations
- Enabling `admin-server-port` must not interfere with the main PostgREST server behavior; the admin server should run alongside the main server.
- The `/health` endpoint must be responsive even during DB outages/recovery attempts (it should reliably return 503 rather than hanging or refusing connections).

4) Configuration
- `admin-server-port` must be recognized in configuration parsing and appear correctly in the effective/normalized configuration output (including when set via environment variables).

The primary user-visible outcome is that, with `admin-server-port` enabled, operators can configure Kubernetes probes to call `http://<host>:<admin-server-port>/health` and receive a fast 200/503 with an empty body, without needing to define a user `/rpc/health_check` function or incur heavy overhead from hitting `/` on large schemas.