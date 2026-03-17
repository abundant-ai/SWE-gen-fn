Using com.cognitect/transcriptor from babashka currently fails because several Clojure runtime features that transcriptor relies on are missing or not exposed.

Reproduction examples:

1) `*source-path*` is not resolvable in babashka when running a script. For example, running a file containing:

```clojure
(println "source-path:" *source-path*)
(println "file:" *file*)
```

should print a value (or at least allow the var to resolve), but instead babashka errors with:

`Could not resolve symbol: *source-path*`

Babashka should provide `clojure.core/*source-path*` as a resolvable dynamic var so that code which binds it (like transcriptor) can run.

2) Transcriptor fails at require-time due to a missing class. Running:

```clojure
(bb -Sdeps '{:deps {com.cognitect/transcriptor {:mvn/version "0.1.5"}}}' 
    -e "(require '[cognitect.transcriptor :as xr :refer (check!)])")
```

currently errors with:

`Unable to resolve classname: clojure.lang.DynamicClassLoader`

Babashka must make `clojure.lang.DynamicClassLoader` available such that code can instantiate it using its constructors.

3) Transcriptor expects `clojure.main/with-read-known` to exist and behave like Clojure’s macro: when `*read-eval*` is `:unknown`, the macro should treat it as enabled/known and produce behavior equivalent to `*read-eval*` being `true` for the duration of the body; for other values of `*read-eval*` (e.g. `false`, `true`, numeric values), the macro should leave the value unchanged.

In other words, the following should evaluate to `true` in babashka:

```clojure
(binding [*read-eval* :unknown]
  (clojure.main/with-read-known *read-eval*))
```

and for other values it should evaluate to the same value that was bound.

4) Transcriptor calls `clojure.core.server/repl-read` during its execution. Babashka should provide `clojure.core.server/repl-read` so that it can read successive forms from the provided input stream and return them one-by-one. It must support reading arbitrary valid Clojure forms (symbols, numbers, lists, nested forms, and multiple forms separated by whitespace/newlines). When it reaches the end of input, it should return the provided request-exit sentinel object (rather than throwing), allowing callers to stop a read loop.

A representative scenario that must work is repeatedly calling `clojure.core.server/repl-read` in a loop, collecting returned forms until the sentinel is returned; given inputs like `"abc"`, `"123 456"`, or a multi-form string containing expressions like `(nil ns/symbol (true))` followed by `(+ 1 2 3)`, the returned sequence should contain exactly the parsed forms in order.

Overall goal: after adding these missing pieces, requiring and running transcriptor (e.g., discovering `.repl` files and running `cognitect.transcriptor/run`) should no longer fail due to missing `*source-path*`, missing `DynamicClassLoader`, missing `clojure.main/with-read-known`, or missing `clojure.core.server/repl-read`.