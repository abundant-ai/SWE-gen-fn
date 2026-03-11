When running code through Babashka’s nREPL server (e.g., from an editor client), `clojure.test/*test-out*` is not properly bound to the session’s output stream. As a result, test output produced via `clojure.test/with-test-out` is lost or written to the wrong place, and `*test-out*` does not match `*out*` inside the evaluated code.

Reproduction in an nREPL session:
```clojure
(require '[clojure.test :refer :all])
(with-test-out (println "this will not be printed"))
(= *test-out* *out*)
```
Current behavior when evaluated through the nREPL server: the `println` inside `with-test-out` does not show up in the client output, and `(= *test-out* *out*)` returns `false`.

Expected behavior: evaluating the same code through the nREPL server should behave like the regular Babashka REPL, where `with-test-out` prints to the client-visible output stream and `(= *test-out* *out*)` returns `true` during evaluation.

Fix the nREPL evaluation/binding logic so that, for each nREPL eval request (and per-session as applicable), the dynamic var `clojure.test/*test-out*` is correctly bound consistently with `*out*` (and thus with the client output stream) during execution of user code. Ensure this works across cloned sessions and typical nREPL interactions (e.g., `clone`, `describe`, `eval`) so that test output is reliably captured and returned to the nREPL client.