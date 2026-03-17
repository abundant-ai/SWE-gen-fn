New Phoenix apps are expected to support LongPoll as a fallback transport for channels, and long polling should be enabled by default in generated code. Currently, when a Socket is constructed and the primary transport (WebSocket) fails to connect, the client may not fall back to LongPoll, and newly generated projects may not have long polling enabled unless the developer manually edits client and endpoint configuration.

When creating a socket connection with `new Socket("/socket", opts)`, the client should default to using the WebSocket transport when available, but it must support automatically switching to long polling when configured to do so.

Specifically:

- `Socket` should accept a `longPollFallbackMs` option. When `longPollFallbackMs` is set to a number, and the initial connection attempt using the primary transport fails (for example, an error/close during connect), the socket should switch transports by calling `socket.replaceTransport(LongPoll)` after the configured delay, then attempt to reconnect using LongPoll.

- The fallback should only occur after a primary transport failure; it should not immediately replace the transport on a healthy connection.

- The `Socket` constructor should keep its existing defaults (such as `endPoint` defaulting to `"/socket/websocket"`, `timeout` defaulting to `10000`, `longpollerTimeout` defaulting to `20000`, `heartbeatIntervalMs` defaulting to `30000`, `binaryType` defaulting to `"arraybuffer"`, and `transport` defaulting to `WebSocket` when available), while allowing these defaults to be overridden via options.

Additionally, newly generated Phoenix applications should have long polling support enabled by default (as requested in issue #5672). That means the generated client setup and server endpoint configuration should include long polling without requiring manual uncommenting or additional edits. A developer should be able to generate a fresh app, deploy it to an environment where WebSockets are unavailable, and still connect to channels via LongPoll automatically when the client is configured with `longPollFallbackMs`.

Expected behavior: a socket configured with `longPollFallbackMs` will transparently recover from an initial WebSocket failure by switching to LongPoll after the specified delay, and new apps ship with long polling enabled by default so this fallback path is functional out of the box.

Actual behavior: long polling fallback is missing or not triggered correctly on WebSocket failure, and/or long polling is not enabled by default in generated apps, causing channel connections to fail in WebSocket-restricted environments.