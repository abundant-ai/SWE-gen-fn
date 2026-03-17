Babashka’s Java interop currently does not support constructing and using `java.io.LineNumberReader` correctly.

When a user tries to create a `java.io.LineNumberReader` wrapping a `java.io.StringReader`, then binds it to `*in*` and reads lines via `read-line`, the reader should correctly track line numbers. For example:

```clojure
(def rdr (java.io.LineNumberReader. (java.io.StringReader. "foo\nbar")))
(binding [*in* rdr]
  (read-line)
  (read-line))
(.getLineNumber rdr)
```

Expected behavior: the final expression should evaluate to `2`, because two lines have been read and the `LineNumberReader` should have advanced its internal line counter accordingly.

Actual behavior: constructing or using `java.io.LineNumberReader` fails in babashka (e.g., the class is not available/allowed for interop), preventing this workflow from working.

Implement support so that `java.io.LineNumberReader` can be instantiated via its constructor (e.g., `(java.io.LineNumberReader. (java.io.StringReader. ...))`), used as an input reader via `binding` to `*in*`, and queried with `.getLineNumber` with correct results after line reads.