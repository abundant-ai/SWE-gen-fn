On Windows, `dune rpc status` incorrectly reports that there is no running RPC server even when a Dune instance is running in watch mode and RPC clients (e.g., ocamllsp) can connect successfully. The command should detect the running RPC server and report its status consistently across platforms.

Reproduce on Windows by starting Dune in watch mode for a project, then from a second terminal running `dune rpc status`. Current behavior: it reports that there is no running RPC server (a false negative). Expected behavior: it should successfully connect to the existing RPC server and display status information rather than claiming no server is running.

Additionally, when the RPC endpoint is genuinely invalid (for example when using an explicit endpoint like `unix:path=foo` where no socket exists), attempting to start an RPC-connected subcommand should fail with a clear error of the form:

`Error: failed to connect to RPC server unix:path=foo`

and include the underlying OS error (on Unix this may be `Unix.Unix_error(Unix.ENOENT, "connect", "")`; on Windows the equivalent connect/ENOENT-style failure should be surfaced). The implementation should ensure Windows endpoint handling and status detection do not spuriously treat a valid running server as missing, while still producing the expected failure message for truly missing/unreachable endpoints.