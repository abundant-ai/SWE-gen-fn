Phoenix socket transports currently always enforce a CSRF token check during connect when session-based connect information is used (such as for Phoenix LiveView sockets). This makes it difficult to publicly cache the initial static HTML for LiveView pages when session is enabled, because the rendered HTML includes a CSRF token that is user-specific; if the HTML is cached and shared, the CSRF token won’t match the connecting user. 

Add support for a new socket transport option named `:check_csrf` for both WebSocket and LongPoll transports. This option must allow applications to explicitly disable the CSRF check while still keeping other protections (notably `check_origin`) enabled.

Expected behavior:

When defining a socket with transport options like:

```elixir
socket "/live", Phoenix.LiveView.Socket,
  websocket: [connect_info: [session: session_opts], check_csrf: false],
  longpoll:  [connect_info: [session: session_opts], check_csrf: false]
```

the transport connection should not be rejected due to a missing or invalid CSRF token. In other words, setting `check_csrf: false` must bypass the CSRF validation step that would otherwise halt the connection with an HTTP 403 response.

When `check_csrf` is not provided (default behavior), CSRF protection must remain enabled exactly as it is today: connections that do not present a valid CSRF token (based on the session) should be rejected.

This new option should be independent of origin checking:

- Disabling CSRF via `check_csrf: false` must not implicitly disable origin checks.
- Existing `check_origin` behavior must remain unchanged (including `check_origin: false`, `check_origin: true`, and endpoint-configured origin lists).

The implementation should ensure that `Phoenix.Socket.Transport` (and any transport-specific code that performs the CSRF verification) respects the `:check_csrf` option consistently across transports, and that incorrect defaults do not accidentally weaken security for existing applications.

If a connection is rejected for CSRF reasons when CSRF checking is enabled, it should continue to behave as it does now (halt the connection with status 403).