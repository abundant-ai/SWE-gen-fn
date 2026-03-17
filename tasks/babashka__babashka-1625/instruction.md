Calling Java methods that return or operate on primitive streams (specifically `java.util.stream.IntStream`) does not work correctly in babashka interop.

A concrete failing case is calling `String.codePoints()` and then invoking `count` on the returned stream. Evaluating:

```clojure
(.count (.codePoints "woof🐕"))
```

should return `5` (the string contains 5 Unicode code points), but currently this call fails due to missing/incorrect interop support for `java.util.stream.IntStream`.

Fix babashka’s Java interop so that instance method invocation works for `java.util.stream.IntStream`, including chaining calls from a Java object method returning an `IntStream` (e.g., `String.codePoints`) into `IntStream` terminal operations (e.g., `.count`). The result of `.count` should be returned to Clojure as a normal number with the correct value.