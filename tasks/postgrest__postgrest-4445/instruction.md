When configuring PostgREST to listen using the special IPv6-only host value `!6`, the server incorrectly binds to an IPv4 address instead of binding IPv6-only.

Reproduction scenario:
- Start PostgREST with `PGRST_SERVER_HOST` (or equivalent config) set to `!6` and a valid `server-port`.
- Attempt to connect over IPv6 loopback (`::1`) to the configured port.

Actual behavior:
- The server is reachable via IPv4 (e.g., `127.0.0.1:<port>`), indicating it bound an IPv4 socket.
- IPv6 connectivity (`[::1]:<port>`) does not behave as expected for an IPv6-only bind.

Expected behavior:
- `server-host = "!6"` must bind the main HTTP listener on IPv6 only (i.e., an IPv6 socket) and should be reachable via `::1` (or the system’s IPv6 interfaces) and not incorrectly fall back to an IPv4 bind.
- The `!6` value should be treated distinctly from other host values (including `*6` and plain hostnames like `localhost`), preserving its intended meaning of IPv6-only binding.

This should work consistently whether the host value is supplied via environment variables or configuration, and it should not require clients to use IPv4 to reach the server when `!6` is configured.