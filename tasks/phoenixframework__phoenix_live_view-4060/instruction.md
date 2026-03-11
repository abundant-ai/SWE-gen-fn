Phoenix LiveView’s `Phoenix.LiveView.JS` commands are designed to be embedded in HTML attributes, but they cannot be reliably sent inside event payloads (for example via `push_event/3`) because the `%Phoenix.LiveView.JS{}` struct is not JSON-serializable in an opaque, stable format expected by the client. As a result, attempting to JSON-encode a JS command for inclusion in an event payload either fails (no encoder) or produces an unsuitable representation, and the client-side `hook.js().exec(...)` pathway cannot consistently consume commands coming from server-driven events.

Add support for sending JS commands from server to client through event payloads by providing an explicit encoding step on the Elixir side and ensuring the JavaScript side can execute the encoded command format.

Implement `Phoenix.LiveView.JS.to_encodable/1` so that when given a `%Phoenix.LiveView.JS{ops: ops}` it returns an opaque JSON-serializable value representing the command sequence. The returned value must be the ops list itself, preserving ordering and each operation’s name and argument map. For example:

```elixir
js = Phoenix.LiveView.JS.push("inc", value: %{one: 1})
Phoenix.LiveView.JS.to_encodable(js)
# => [["push", %{event: "inc", value: %{one: 1}}]]
```

For multiple operations, `to_encodable/1` must return a list of operations in order, such as:

```elixir
js =
  Phoenix.LiveView.JS.push("inc", value: %{one: 1, two: 2})
  |> Phoenix.LiveView.JS.add_class("show", to: "#modal", time: 100)
  |> Phoenix.LiveView.JS.remove_class("hidden")

Phoenix.LiveView.JS.to_encodable(js)
# => [
#  ["push", %{event: "inc", value: %{one: 1, two: 2}}],
#  ["add_class", %{names: ["show"], to: "#modal", time: 100}],
#  ["remove_class", %{names: ["hidden"]}]
# ]
```

Additionally, make `%Phoenix.LiveView.JS{}` encodable by common JSON encoders so that users can pass JS commands directly into JSON payloads without manually calling `to_encodable/1`. Specifically:

- `Jason.encode!(%Phoenix.LiveView.JS{...})` must succeed and produce JSON that decodes back into the same list-of-ops shape (e.g. decoding yields `[["push", %{"event" => "inc", "value" => %{"one" => 1}}]]]`).
- If the standard library `JSON` module is available, `JSON.encode!(%Phoenix.LiveView.JS{...})` must also succeed with equivalent semantics.

On the client side, ensure `hook.js().exec(...)` can execute JS commands provided in this encoded form both when given as a JSON string (e.g. `'[["toggle", {"to": "#modal"}]]'`) and when given as the already-parsed command array value (e.g. `[["toggle", { to: "#modal" }]]`). Executing a valid encoded command should apply the expected DOM behavior (for example, executing a `toggle` command targeting `#modal` should toggle that element’s visibility).

The end result should allow a LiveView to construct a `Phoenix.LiveView.JS` command server-side, include it in an event payload, JSON-encode it successfully, and have the client receive and execute it via the existing JS command execution APIs.