The JavaScript Socket client currently relies on a global browser-like environment being provided by the test runner (jsdom) in order to compute URLs and protocols. In environments that don’t run with a global jsdom window/location (or where jsdom is only enabled for specific suites), creating a `new Socket("/socket")` can produce incorrect endpoint URLs/protocols or throw because `window.location` is missing.

The client should not require a globally configured jsdom environment just to determine the websocket endpoint. When calling `socket.protocol()` with an HTTP page context, it must return `"ws"` (and for HTTPS it must return `"wss"`). When calling `socket.endPointURL()` for a socket created as `new Socket("/socket")` under an HTTP origin `http://example.com/`, it must produce exactly:

```js
"ws://example.com/socket/websocket?vsn=2.0.0"
```

The behavior must be correct without depending on a globally configured jsdom environment for the whole test run; code that uses `Socket` and `LongPoll` should work when only minimal globals are available (e.g., when WebSocket/XMLHttpRequest are mocked) and should not require the entire process to be in a browser-like DOM environment.

Fix the Socket client’s URL/protocol resolution so that it is robust when `window`/`location` are not globally present, while still producing the correct protocol and endpoint URL when a location is available. Ensure that normal transport-related behavior (WebSocket and LongPoll usage) continues to function with mocked `window.WebSocket` and `global.XMLHttpRequest`.