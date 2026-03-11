In babashka’s REPL, the help output advertises that users can inspect implementation with `(source ...)`, but calling `source` on built-in Clojure vars (e.g., `map`, `+`, etc.) currently fails and prints `Source not found`. This makes the REPL inconsistent with Clojure’s REPL experience where `(source map)` and `(source +)` show the function’s source.

Reproduce by starting a `bb` REPL and evaluating:

```clojure
(source map)
(source +)
```

Actual behavior: the REPL prints `Source not found`.

Expected behavior: `source` should be able to return/show source for built-in vars as well, so that evaluating `(source <built-in-var>)` prints the corresponding definition (similar to Clojure’s REPL). For example, calling `(source +)` should display the `defn` form for `+`.

Additionally, built-in vars should have meaningful source location metadata so that when exceptions produce stack traces, frames referencing `clojure.core` built-ins include a file/line location originating from Clojure’s core source rather than missing/placeholder locations. This should be consistent enough that stack traces for expressions involving core functions show a stable built-in location (e.g., something like `clojure/core.clj:<line>:<col>` rather than no source), while user code continues to show its actual source locations.