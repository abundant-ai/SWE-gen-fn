Requiring `flatland.ordered.set` in babashka currently fails at runtime because the class `clojure.lang.ITransientSet` is not available/resolvable in the babashka environment.

Reproduction:
1) Start a babashka REPL.
2) Evaluate:
```clojure
(require '[flatland.ordered.map :as om])
(require '[flatland.ordered.set :as os])
```

Actual behavior:
The second require fails with an error like:

```
java.lang.Exception: Unable to resolve classname: clojure.lang.ITransientSet
```

Expected behavior:
- `(require '[flatland.ordered.set :as os])` should succeed in babashka, the same way `(require '[flatland.ordered.map :as om])` already does.
- `flatland.ordered.set/ordered-set` should be available to users and behave like an ordered set implementation (e.g., it can be constructed and used from babashka code without class resolution errors).
- Any transient operations used internally by `flatland.ordered.set` must work without missing-interface/class errors; in particular, babashka must support the `clojure.lang.ITransientSet` interface well enough for libraries relying on it to load and run.

Example usage that should work after the fix:
```clojure
(require '[flatland.ordered.set :refer [ordered-set]])
(ordered-set 3 1 2) ; should construct an ordered set without throwing
```

Fix the runtime/library exposure so that babashka can load `flatland.ordered.set` and resolve `clojure.lang.ITransientSet` successfully, preventing the above exception.