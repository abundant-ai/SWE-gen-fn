Channel authentication currently encourages passing an access token via the socket URL (connection params), which commonly results in the token being included in GET request URLs and therefore exposed in logs and intermediary infrastructure. This can leak bearer tokens and allow user impersonation.

Update the channel/socket connection flow to support transport-agnostic token passing without putting the token in the URL.

When creating a `Socket` with an authentication token (using the `authToken` option), connecting over WebSocket must send the token via the WebSocket subprotocol negotiation instead of query params. Specifically, `Socket#connect()` should construct the `WebSocket` with a `protocols` list that includes the standard `"phoenix"` protocol plus a second protocol value derived from the token in the form:

`base64url.bearer.phx.<BASE64URL_ENCODED_TOKEN>`

For example, with `authToken = "1234"`, the negotiated protocols must be:

`["phoenix", "base64url.bearer.phx.MTIzNA"]`

In addition to WebSocket support, LongPoll connections must also be able to authenticate without URL token leakage by sending the token in an `Authorization` header (bearer-style) rather than as a query parameter.

Expected behavior:
- Passing `authToken` to `new Socket(endpoint, {authToken})` must not append the token to the connection URL for either WebSocket or LongPoll.
- For WebSocket, the token must be transmitted via `Sec-WebSocket-Protocol` using the encoded protocol value above.
- For LongPoll, the token must be transmitted via an `Authorization` header.
- Existing channel join behavior and parameters must continue to work as before; the change should only affect how the token is transported during the initial socket connection/handshake.

Actual behavior to fix:
- Tokens passed for channel authentication end up in the URL, making them visible in logs and upstream components, and WebSocket connections do not negotiate the token via `Sec-WebSocket-Protocol`.