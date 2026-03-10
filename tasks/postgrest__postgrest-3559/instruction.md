PostgREST currently allows configuring `server-port` and `admin-server-port` to the same numeric value, which can lead to a confusing and unsafe startup state where both the main HTTP server and the admin server report listening on the same port (e.g., one ends up bound via IPv4 and the other via IPv6). For example, starting PostgREST with environment variables like:

```
PGRST_SERVER_PORT=3000
PGRST_SERVER_HOST=localhost
PGRST_ADMIN_SERVER_PORT=3000
```

can result in logs indicating both servers are listening on port 3000. This should be rejected at configuration validation time.

When `server-port` equals `admin-server-port`, PostgREST should fail fast during configuration parsing/validation (before attempting to start either listener) with a non-zero exit code. The error should clearly indicate that `server-port` and `admin-server-port` must not be equal.

This validation should apply regardless of whether the admin server and main server might bind to different addresses; the configuration must forbid equal values altogether. Running PostgREST in a mode that prints the parsed configuration (e.g., via the CLI flag that dumps config) should also error out if the two ports are equal, since config validation should happen even when not starting the servers.