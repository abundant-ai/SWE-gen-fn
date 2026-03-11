When babashka evaluates code that does not originate from a physical file (for example, running an expression passed directly on the command line / via an in-memory string), exceptions produce stack traces that currently show an “unknown” or placeholder file path. This placeholder is inconsistent and should be standardized.

Repro:
Run an expression that throws, e.g.:

```clojure
(defn foo [] (/ 1 0))
(foo)
```

The resulting exception message includes a formatted stack trace with entries for `clojure.core//` and `user/foo`.

Expected behavior:
For frames whose source does not come from an actual file, the stack trace should display `NO_SOURCE_PATH` as the “file”, including line and column info where applicable. For example, the stack trace should include lines like:

- `clojure.core// - <built-in>`
- `user/foo       - NO_SOURCE_PATH:2:14`
- `user/foo       - NO_SOURCE_PATH:2:1`
- `user           - NO_SOURCE_PATH:3:1`

Actual behavior:
These same frames display an “unknown file” path (or another placeholder) instead of `NO_SOURCE_PATH`, causing the stack trace to not match the expected formatting.

Fix the stacktrace/source-location rendering so that any unknown/missing source path is consistently rendered as `NO_SOURCE_PATH` in the exception output, without affecting stack traces coming from real scripts/files (which should continue to show the actual script filename with correct line/column information).