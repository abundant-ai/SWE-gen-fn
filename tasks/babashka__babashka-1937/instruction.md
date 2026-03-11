Babashka’s interactive REPL has compatibility issues when used through JLine-based line readers such as rebel-readline, especially around multi-line input, interrupts, and end-of-input handling.

When running the REPL via a JLine `LineReader` (e.g. through `repl-with-line-reader` / `start-repl!`), the REPL should correctly support JLine-style multi-line editing where `readLine` is called repeatedly to accumulate input until a complete Clojure form is available. The REPL should only attempt to evaluate once the form is complete, using the same completeness rules as `complete-form?`.

Currently, certain sequences of inputs cause incorrect behavior such as prematurely evaluating incomplete forms, failing to preserve already-entered lines across JLine calls, or mishandling JLine exceptions. In particular:

- Multi-line forms: entering a form split across multiple lines (e.g. an open list/vector/map that is completed on later lines) should not be evaluated until the form is complete. The REPL should continue prompting/reading additional lines until `complete-form?` indicates the accumulated input is complete.

- Interrupts: if the underlying line reader throws `org.jline.reader.UserInterruptException` while the user has partially typed a multi-line form, the REPL should treat this as an interrupt of the current input (clearing the pending accumulated input) and remain usable for subsequent inputs. It should not evaluate the partial form, and it should not leave the REPL in a broken state.

- EOF behavior: if the underlying line reader throws `org.jline.reader.EndOfFileException` on an empty prompt (simulating Ctrl+D), the REPL should exit cleanly. If EOF happens while a partial multi-line form is being entered, the REPL should not attempt to evaluate an incomplete form and should handle the condition gracefully (either exiting cleanly or reporting an appropriate error without crashing).

These behaviors should work when using `repl-with-line-reader` and should integrate with existing REPL features such as autocompletion (`word-at-cursor`, `common-prefix`, `compute-tail-tip`), doc formatting (`format-doc`), and any logic that depends on `enclosing-fn`.

Reproduction example (conceptual): using a JLine line reader that returns successive lines like "(defn foo []" then "  (+ 1 2))" should result in defining `foo` only after the second line is entered; an interrupt mid-way through should cancel the input and allow entering a new expression like "(+ 1 2 3)" and getting `6` normally.

Fix the REPL’s line-reading/evaluation loop so these JLine multi-line, interrupt, and EOF scenarios behave correctly and consistently, improving rebel-readline compatibility.