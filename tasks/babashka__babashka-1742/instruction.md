Babashka’s Java interop does not fully match Clojure 1.12 behavior for coercing Clojure functions (IFn) into Java functional interfaces (“FI coercion”). As a result, passing a Clojure predicate/function into certain JDK methods that expect a functional interface fails or behaves incorrectly.

Update babashka’s interop so that common JDK APIs accepting functional interfaces work the same way as in Clojure 1.12 when given an IFn (including plain functions and predicates like `even?`, `Character/isDigit`, and anonymous functions like `#(str % %)`), without requiring users to manually wrap with `reify`/`proxy`.

The following scenarios must work:

1) Predicates passed to `java.util.Collection/removeIf` should be accepted and invoked correctly. Example:
```clojure
(= [1 3]
   (into []
         (doto (java.util.ArrayList. [1 2 3])
           (.removeIf even?))))
```
Expected result is `true` for the equality.

2) Functions passed to `java.util.Map/computeIfAbsent` should be accepted and invoked with the map key. Example:
```clojure
(= "abcabc"
   (.computeIfAbsent (java.util.HashMap.) "abc" #(str % %)))
```
Expected result is `true` for the equality.

3) Static Java methods used as predicates (e.g. `Character/isDigit`) must be usable where a functional interface predicate is required, such as when working with Java streams. Example:
```clojure
(= '(\9)
   (-> "a9-" seq .stream (.filter Character/isDigit) stream-seq!))
```
Expected result is `true` for the equality.

Additionally, IFn implementations created via `reify clojure.lang.IFn` must continue to behave correctly across multiple arities and via `apply`/`applyTo`. For example, a reified IFn supporting multiple `invoke` arities plus `applyTo` should return the correct values when called with different argument counts and when invoked via `(apply f (range 20))`.

Fix the FI/IFn coercion so these interop calls succeed and produce the expected results (matching Clojure 1.12 semantics), rather than throwing errors about incompatible argument types / method selection failures or invoking with wrong arity/arguments.