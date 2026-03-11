Phoenix is missing a small debugging/introspection API for discovering running Channel socket processes and the channels attached to them. Implement a `Phoenix.Debug` module that can:

- `list_sockets/0`: return a list of all currently connected channel socket processes. Each entry must include at least the socket process `pid` and the socket module (`module`). The function should return a list (possibly empty) and must include socket processes that identify themselves as Phoenix sockets via process labeling.

- `socket_process?/1`: return `true` when the given pid is a running Phoenix channel socket process, and `false` otherwise (including for the current process when it is not a socket process).

- `channel_process?/1`: return `true` when the given pid is a running Phoenix channel process, and `false` otherwise.

- `list_channels/1`: given a socket pid, return `{:ok, channels}` where `channels` is a list of maps describing channels managed by that socket. Each channel entry must include at least `:pid`, `:status`, and `:topic`. If the pid is not alive or is not a socket process, return `{:error, :not_alive}`.

- `socket/1`: given a channel pid, return `{:ok, %Phoenix.Socket{}}` for channel processes that can provide their socket via a `:socket` call. If the pid is not alive or is not a channel process, return `{:error, :not_alive_or_not_a_channel}`.

Behavioral details:
- The identification of socket and channel processes must rely on the conventional Phoenix process labeling used by sockets/channels (i.e., processes tagged as `Phoenix.Socket` or `Phoenix.Channel` with associated metadata).
- `list_channels/1` must actively request channel information from the socket process and return the channels it reports (including correct `topic` values like `"room:lobby"`).
- Error tuples and atoms must match exactly: `{:error, :not_alive}` for `list_channels/1` invalid pids, and `{:error, :not_alive_or_not_a_channel}` for `socket/1` invalid pids.

Example expectations:
- If a socket process exists, `Phoenix.Debug.list_sockets()` should include an entry with that socket’s pid and module.
- If a channel process exists, `Phoenix.Debug.socket(channel_pid)` should return `{:ok, %Phoenix.Socket{}}`.
- Calling `Phoenix.Debug.list_channels(non_socket_pid)` should return `{:error, :not_alive}`.