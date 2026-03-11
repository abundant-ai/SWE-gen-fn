Sensitive form values can leak in crash reports when a LiveView form is submitted and the process crashes. Specifically, when a `%Phoenix.Socket.Message{}` representing a LiveView submit event is inspected (e.g., appears as the “Last message” in a GenServer crash), the payload contains a string field `payload["value"]` that holds URL-encoded form data such as `"username=john&password=secret123"`. This `"value"` string is currently displayed verbatim by `inspect/2`, so configured parameter filtering/scrubbing is not applied and secrets like passwords may appear in logs.

Update the custom `Inspect` implementation for `Phoenix.Socket.Message` so that, for LiveView form submit messages, sensitive parameters embedded inside `payload["value"]` are filtered in the inspected output.

A message should be treated as a LiveView form submit when it matches the shape:
- `topic` like `"lv:..."`
- `event` is `"event"`
- `payload` includes `"event" => "submit"`, `"type" => "form"`, and a binary `"value"` containing a query-string-like payload.

When calling `inspect(message)` on such a message, the output should replace sensitive values (e.g., `password`) with `[FILTERED]` while leaving non-sensitive keys/values intact. For example, inspecting a message with `payload["value"] == "username=john&password=secret123&email=john@example.com"` should include `"username=john"` and `"email=john@example.com"` but must include `"password=[FILTERED]"` (not the original secret). This should also work when the sensitive field is the last parameter in the string (e.g., `"username=john&password=secret123"`).

The implementation must be robust to malformed or unexpected `payload["value"]` contents (for example `"invalid=query=string&password=secret"`), and `inspect/2` must still return a valid string without raising exceptions in these cases.