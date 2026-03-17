In babashka (e.g., v1.3.188 on Linux), wrapping Taoensso Timbre’s built-in macro `taoensso.timbre/log!` inside a function fails at definition time, even though the same code works on regular Clojure.

Reproduction:
```clojure
(require '[taoensso.timbre :as timbre])

(defn log-wrapper [& args]
  (timbre/log! :warn :p args))
```

Expected behavior: the function `log-wrapper` should compile/define successfully, and calling it like:
```clojure
(log-wrapper "hallo")
```
should log a WARN message via Timbre and return normally (matching Clojure’s behavior). This wrapping pattern is required to allow binding logging behavior through a dynamic var when the underlying API is a macro.

Actual behavior in babashka: defining `log-wrapper` throws:

`java.lang.IllegalArgumentException: Don't know how to create ISeq from: clojure.lang.Symbol`

Fix babashka’s Timbre integration / macro expansion so that `timbre/log!` can be invoked from within a function body (including with variadic `& args` passed through), without throwing the above exception. The fix should not break existing Timbre logging functionality, including:
- `timbre/debug` / `timbre/info` emitting logs at the expected levels
- changing log levels via `alter-var-root` on `timbre/*config*`, `timbre/with-level`, and `timbre/set-level!`
- formatted logging (`timbre/infof`)
- appenders that write to standard output and to a file (e.g., via `timbre/spit-appender` and `timbre/swap-config!`), including working correctly when logs are captured with `with-out-str`.