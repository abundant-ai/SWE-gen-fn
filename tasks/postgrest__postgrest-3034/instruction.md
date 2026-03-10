When PostgREST is started with the configuration value `server-port = 0` (or env var `PGRST_SERVER_PORT=0`), it successfully binds to an ephemeral TCP port chosen by the OS, but the startup log message is misleading and reports `Listening on port 0`. This makes it impossible for users to discover which port the service is actually reachable on.

Reproduction:
1) Start PostgREST with `PGRST_SERVER_PORT=0 postgrest postgrest.conf`.
2) Observe that PostgREST starts and accepts connections.
3) Observe the log line similar to: `Listening on port 0`.

Expected behavior:
- `server-port=0` must be treated as a supported, documented configuration value meaning “bind to a random available TCP port”.
- After binding, PostgREST must report the actual TCP port it ended up listening on (the kernel-assigned ephemeral port), not `0`.
- The logged address/port information should correspond to the real bound socket so that users can connect using the advertised port.

Actual behavior:
- The application logs `Listening on port 0` even though the socket is bound to a non-zero ephemeral port.

Implement the fix so that:
- The configuration layer and startup/binding logic explicitly handle the special value `0` for `server-port`.
- The server determines the real bound port from the listening socket and uses it in the startup message.
- This works consistently across supported platforms, including cases where Unix domain sockets are not available (those should be detected at runtime and handled without causing misleading output or platform-specific failures).

The change should preserve normal behavior for non-zero `server-port` values and continue to start the main application successfully with the configured sockets initialized (e.g., via `PostgREST.App.postgrest` and `PostgREST.AppState.initSockets`).