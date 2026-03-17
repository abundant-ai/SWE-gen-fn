Babashka’s error reporting output needs to be updated to match Clojure 1.12 semantics so that stack traces and context snippets remain stable and informative.

Currently, when a runtime exception occurs (e.g., dividing by zero inside a function evaluated from an expression or loaded from a script), the exception message produced by Babashka does not match the expected “pretty” stack trace formatting. In particular, the formatted stack trace should include entries using the Clojure 1.12-style namespace/function display and should correctly attribute frames to either built-in functions, evaluated expressions, or script files with accurate line/column information.

Reproduction examples:

1) Evaluated expression stacktrace

Evaluating code like:

```clojure
(defn foo [] (/ 1 0))
(foo)
```

should throw an exception whose message includes a stack trace section like:

- A header line starting with:
  `----- Stack trace -----`
- A frame for the built-in divide operation shown as:
  `clojure.core// - <built-in>`
- Frames for the user function showing both the call site and the definition site:
  `user/foo - <expr>:2:14`
  `user/foo - <expr>:2:1`
- A frame for the top-level expression:
  `user - <expr>:3:1`

At the moment, Babashka may emit different frame names/ordering, omit the `clojure.core//` built-in representation, or produce incorrect `<expr>` coordinates.

2) Evaluated expression context snippet

For the same expression, the exception message should also include a context section like:

- A header line starting with:
  `----- Context -----`
- A short excerpt of the form showing the error location and message aligned under the offending form, e.g. indicating `Divide by zero` with a caret pointing under the `/` inside `(/ 1 0)`.

If the context is missing, the caret alignment is wrong, or the message differs from `Divide by zero`, this should be corrected.

3) Script stacktrace attribution

When running a script file that defines functions and triggers divide-by-zero, the resulting stack trace should:

- Include a `clojure.core//` built-in frame.
- Attribute `user/foo` and `user/bar` frames to the script file name with correct line and column positions (e.g. `...divide_by_zero.bb:2:3`, `...:1:1`, etc.).
- Include a final `user` frame pointing to the script location where evaluation happens.

The current behavior may produce different formatting or incorrect/unstable locations when running from a file.

Fix Babashka’s Clojure 1.12 integration so that exception messages (via `ex-message`) contain the expected stack trace and context sections, with stable frame naming, ordering, and accurate source locations for both `<expr>` evaluation and script execution.