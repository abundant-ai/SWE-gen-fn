Calling Java methods via interop fails when a numeric argument is not already a boxed long, specifically for `Thread/sleep` on JDK-19-based runtimes.

Reproduction:
```clojure
(Thread/sleep (/ 1 2))
```
This currently throws an interop error because the argument produced by `(/ 1 2)` is not treated as a valid `long` for the `Thread/sleep(long)` overload.

Expected behavior: numeric values that are semantically usable as a Java `long` (including ratios/decimals that can be coerced to a long the same way an explicit `(long ...)` cast would) should be accepted by interop argument boxing/coercion so that this works:
```clojure
(Thread/sleep (/ 1 200))
(Thread/sleep (/ 1 200) (/ 1 200))
(Thread/sleep (java.time.Duration/ofMillis 1))
```
The first two calls should resolve to the correct `Thread/sleep(long)` and `Thread/sleep(long,int)` overloads without requiring the user to manually wrap arguments with `(long ...)`. The Duration overload should continue to work.

Actual behavior: the ratio-based forms fail on newer JDKs unless the user explicitly coerces, e.g.:
```clojure
(Thread/sleep (long (/ 1 2)))
```

Fix the interop argument boxing/coercion logic used during reflective method selection/invocation so that `Thread/sleep` correctly accepts non-long numeric values where a `long` parameter is required, restoring compatibility on JDK 19+ while preserving correct overload resolution.