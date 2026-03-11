In babashka, objects created with `(reify Object ...)` do not currently behave like JVM Clojure when overriding `equals` and/or `hashCode`. In JVM Clojure, providing an `equals` implementation on a `reify Object` instance affects Clojure’s `=` comparison, but in babashka the override is ignored (or not wired correctly), causing `=` to return the wrong result.

Reproduction:
```clojure
(def any-number
  (reify Object
    (equals [_ other]
      (number? other))))

(= any-number 42)
```
Expected behavior: the expression returns `true`, matching JVM Clojure semantics.
Actual behavior: it returns `false` in babashka.

The runtime should correctly support overriding the following `Object` methods on `reify` instances and have Clojure operations respect them:

- `equals(Object)`
  - When `equals` is overridden on a `reify Object` value, `(= reified x)` must delegate to that `equals` implementation.
  - When `equals` is not overridden, default identity-based equality should apply: the object must compare equal to itself and not equal to unrelated values.

- `hashCode()`
  - When `hashCode` is overridden on a `reify Object` value, `(hash reified)` must return the overridden value.
  - When `hashCode` is not overridden, `(hash reified)` must still return a valid number (the default object hash behavior should continue to work).

Additionally, overriding `toString()` on a `reify Object` value should continue to work (e.g., `(str obj)` should use the overridden `toString`), and overriding `toString` alone must not break hashing (calling `(hash obj)` should still succeed and return a number).

The goal is for babashka’s `reify Object` semantics for `equals` and `hashCode` (and their interaction with `=`, `not=`, and `hash`) to match JVM Clojure for the scenarios above.