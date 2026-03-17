Babashka’s implementation of `clojure.test/use-fixtures` does not mirror Clojure’s behavior of recording fixtures in namespace metadata. This breaks tooling that inspects `*ns*` metadata to discover fixtures (e.g., when building a test plan).

In Clojure, after calling `(clojure.test/use-fixtures :each f)` or `(clojure.test/use-fixtures :once f)`, the current namespace’s metadata should include the corresponding keys with the fixtures that were registered:

- `:clojure.test/each-fixtures` (also accessible as `::clojure.test/each-fixtures` when `clojure.test` is aliased)
- `:clojure.test/once-fixtures` (also accessible as `::clojure.test/once-fixtures`)

Current behavior in babashka:

- Calling `clojure.test/use-fixtures` correctly affects fixture execution during `clojure.test/run-tests`, but `(meta *ns*)` does not get updated with `:clojure.test/each-fixtures` / `:clojure.test/once-fixtures`.
- As a result, `(some? (::t/each-fixtures (meta *ns*)))` and `(some? (::t/once-fixtures (meta *ns*)))` evaluate to false/nil after registering fixtures.

Expected behavior:

- After `(t/use-fixtures :once once-fixture)`, `(meta *ns*)` must contain `:clojure.test/once-fixtures` mapped to a collection containing `once-fixture`.
- After `(t/use-fixtures :each each-fixture)`, `(meta *ns*)` must contain `:clojure.test/each-fixtures` mapped to a collection containing `each-fixture`.
- This metadata should be present while running tests so that fixtures can be discovered and so that printing `(some? (::t/once-fixtures (meta *ns*)))` and `(some? (::t/each-fixtures (meta *ns*)))` after fixtures run results in `true`.

Reproduction example:

```clojure
(require '[clojure.test :as t])

(defn my-fixture [f]
  (println "Hello world")
  (f))

(t/use-fixtures :each my-fixture)

;; Expected: meta contains :clojure.test/each-fixtures
(println (some? (::t/each-fixtures (meta *ns*))))
```

The `use-fixtures` behavior in babashka should be updated so that registering fixtures updates `*ns*` metadata the same way Clojure does, for both `:once` and `:each`.