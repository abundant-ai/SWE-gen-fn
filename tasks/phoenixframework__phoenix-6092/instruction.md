Phoenix endpoints can be configured with different HTTP server adapters (for example, Cowboy and Bandit). When an endpoint is configured to run with `Bandit.PhoenixAdapter`, Phoenix’s socket transports (WebSocket and LongPoll) should behave identically to when running under `Phoenix.Endpoint.Cowboy2Adapter`.

Currently, running the same socket and channel flows under `Bandit.PhoenixAdapter` does not fully match Cowboy behavior, causing integration scenarios to fail. The failures show up in areas that are sensitive to the webserver’s request/connection metadata and upgrade handling:

- Origin enforcement must work the same way for both WebSocket and LongPoll sockets. When a socket is configured with `check_origin: ["//example.com"]`, connections from other origins must be refused, and connections from allowed origins must succeed.
- WebSocket endpoints must support:
  - passing params through connect such that `connect(%{params: params, transport: :websocket, endpoint: Endpoint})` receives the expected params and server-side replies can reflect them;
  - custom socket mount paths where the socket definition includes a `path:` option such as `"nested/path"` or `":path_var/path"` and requests to the corresponding URL should route correctly;
  - subprotocol negotiation when `subprotocols: ["sip"]` is configured.
  - ping/control frame handling via a transport callback `handle_control({payload, opts}, state)` where `opts` includes an `:opcode` and the server pushes a text response like `"#{opcode}:#{payload}"`.
- LongPoll endpoints must support:
  - routing for default and custom mount paths (including dynamic segments) similar to WebSocket;
  - correct JSON request/response behavior for polling endpoints, including decoding/encoding consistent with `Phoenix.json_library()`;
  - correct behavior for socket callbacks that expect to receive `transport: :longpoll` and params in `connect/1`.
- Channel flows over LongPoll must work under Bandit the same way they do under Cowboy, including join, broadcast, push, and intercept behavior. In particular, a channel may push payloads that include information derived from the transport (e.g., including `inspect(socket.transport)` in outgoing payloads), and that should reflect the correct transport module/identifier.
- `connect_info`-dependent behavior must be consistent. When sockets read from `connect_info` (peer address, URI, x-headers, trace-context headers), the data must be present and in the expected shape so socket `connect/3` logic can normalize it.

Implement/adjust the Phoenix endpoint adapter integration so that when an endpoint is started with `adapter: Bandit.PhoenixAdapter` and `server: true`, all of the above behaviors work equivalently to Cowboy. This includes ensuring that request origin, routing/path generation for socket mounts, websocket upgrade metadata (including subprotocols), and longpoll request handling provide Phoenix the information it expects.

A minimal reproduction is to start a Phoenix endpoint configured with sockets mounted at `/ws` and `/custom/:socket_var`, run it once with `adapter: Phoenix.Endpoint.Cowboy2Adapter` and once with `adapter: Bandit.PhoenixAdapter`, and verify that the same WebSocket and LongPoll interactions (connect with params, enforce `check_origin`, negotiate subprotocols, respond to ping/control frames, and run channel join/broadcast/push flows) succeed/fail in the same cases for both adapters.