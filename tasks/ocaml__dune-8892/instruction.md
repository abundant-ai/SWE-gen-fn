On Windows, `dune rpc`-based commands (including `dune internal action-runner start …`) do not fail cleanly when asked to connect to a non-existent RPC endpoint. When the environment variable `DUNE_RPC` is set to a Unix-domain socket style endpoint like `unix:path=foo` and the command is run without a server listening, the command should report a clear connection failure message and include the underlying Unix error.

Reproduction example:

```sh
DUNE_RPC="unix:path=foo" dune internal action-runner start foobar
```

Expected behavior: the command exits with an error whose message begins with:

`Error: failed to connect to RPC server unix:path=foo`

and it should also surface the underlying exception:

`Unix.Unix_error(Unix.ENOENT, "connect", "")`

followed by a backtrace header (`backtrace:`).

Actual behavior (current bug): on Windows this invocation does not produce the expected failure output (it may error differently, fail earlier with a parsing/transport issue, or not surface the intended “failed to connect” message), making `dune rpc` commands unreliable on Windows when the RPC server is missing.

Fix the RPC client connection path used by these commands so that, on Windows as well as other platforms, attempting to connect to a missing RPC server consistently fails with the error text shown above (including preserving the endpoint string `unix:path=foo` in the message) and returns a non-zero exit status.