Babashka currently creates non-daemon threads for `future`/agent-style asynchronous execution. This causes scripts to hang after the main code finishes unless users manually call `(shutdown-agents)` to terminate those threads. In contrast, `clojure -X` uses a thread pool factory that creates daemon threads for `future`-like execution, so scripts can exit normally without extra cleanup.

Update babashka so that the executor used by `future` (and any related agent send-off / async execution that shares the same pool) can use daemon threads, matching the `clojure -X` behavior, but keep the existing “wait for non-daemon threads before exiting” behavior available behind a CLI flag (e.g. `--wait-non-daemon-threads` or an experimental equivalent). The default behavior should be the daemon-thread behavior (so that scripts exit without requiring `(shutdown-agents)`), while the flag should opt into waiting/blocking behavior compatible with today’s non-daemon semantics.

This change must also define what happens on error-driven exits. If a program throws an exception intended to terminate the process (including exceptions carrying `{:babashka/exit 1}`), babashka should not keep the process alive just because background async work is running; it should exit with the requested non-zero status (consistent with `clojure -X` throwing in situations like:

```clojure
(defn exec [_]
  (org.httpkit.server/run-server {})
  (throw (ex-info "Dude" {})))
```

After the change, it should be possible to run code that starts background work via `future` (or other APIs that rely on the same executor) and have the process terminate cleanly when the main thread finishes, unless the user explicitly requests waiting for non-daemon threads via the new flag.