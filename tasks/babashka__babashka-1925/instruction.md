In the interactive REPL, requesting documentation/help for a symbol should behave consistently and not break REPL input handling, cursor-based utilities, or completion-related features.

Currently, REPL “docs in repl” support is incomplete/incorrect in a few ways:

When formatting documentation for a symbol using `format-doc`, the output is not reliably produced in a REPL-friendly way. Documentation should be formatted as a human-readable string suitable for printing in the REPL, and it should work for typical Clojure/Sci vars and namespaces available in the session.

In addition, the REPL utilities that support interactive editing features must continue to behave correctly alongside doc lookup:

- `word-at-cursor` should correctly extract the symbol under the cursor in a line of input (so doc lookup can be performed on the right identifier). It must handle common cursor positions, including when the cursor is at the end of the word, inside the word, or adjacent to non-symbol delimiters like whitespace and parentheses.
- `enclosing-fn` should correctly identify the currently enclosing function form based on the input text and cursor position, so that doc/help features don’t mis-detect context in nested forms.
- Completion helpers like `common-prefix`, `compute-tail-tip`, and `complete-form?` must continue to return correct results for multi-line input and partially typed forms, without being affected by doc/help output formatting.

Expected behavior: when a user triggers doc display for a symbol available in the REPL session, the REPL prints a correctly formatted doc string (including relevant name/namespace and doc text when available), and interactive input behavior (multi-line detection, completion, cursor-based word detection) continues to function normally.

Actual behavior: doc formatting/display from within the REPL is missing or incorrectly formatted, and/or interacting with doc lookup can lead to incorrect word-at-cursor extraction or context detection, resulting in wrong symbol lookup or broken/incorrect completion behavior.

Implement/adjust REPL doc support so that `format-doc` produces appropriate output for REPL display, and ensure the related helper functions (`word-at-cursor`, `enclosing-fn`, `common-prefix`, `compute-tail-tip`, `complete-form?`) behave correctly in the presence of doc/help usage within typical REPL editing scenarios.