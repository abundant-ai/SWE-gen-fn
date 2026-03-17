Babashka’s nREPL server is missing support for the standard “classpath” nREPL operation. Clients that send an nREPL message with `{"op" "classpath" ...}` cannot retrieve the runtime classpath, even though this operation is expected by tooling that integrates with nREPL.

When a client connects to the nREPL server, clones a session, and then sends a request like:

```clojure
{"op" "classpath" "session" session-id "id" request-id}
```

the server should reply for that same `session` and `id` with a message that includes a `classpath` field containing the current classpath entries as a collection of strings (paths). The reply must also indicate successful completion via the usual nREPL `status` semantics (e.g., including a “done” status).

Currently, this operation is not implemented (or not advertised/handled correctly), so clients cannot obtain the classpath via nREPL. Implement the “classpath” op end-to-end so that:

- The op is recognized and handled by the nREPL message dispatcher.
- The response includes a `classpath` key whose value is the runtime classpath as a sequence/vector of string paths.
- The operation works within an active session and responses are correlated correctly by `id` and `session`.
- The server’s “describe” operation advertises that the “classpath” op is supported (so clients can discover it).

After the change, connecting to the server and issuing the “classpath” op should return a non-empty classpath (when the runtime has classpath entries) and should not interfere with existing ops like `clone`, `describe`, and `eval`.