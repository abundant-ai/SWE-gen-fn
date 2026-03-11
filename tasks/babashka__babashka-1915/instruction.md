REPL completions are not behaving correctly when using the line-reader based REPL. The REPL should support JLine-style multi-line input accumulation (reading multiple lines until a complete Clojure form is present) and provide correct completion utilities.

When starting the REPL via start-repl! and using repl-with-line-reader, the reader loop must accumulate lines until complete-form? returns true for the accumulated input; only then should the form be evaluated. If input is exhausted, the line reader should result in an EndOfFileException so the REPL exits cleanly. If a user interrupt occurs (UserInterruptException) while a partial form has been accumulated, the REPL should discard the accumulated partial input and continue prompting rather than trying to evaluate an incomplete form or leaving the REPL in a broken state.

In addition, completion helpers must behave correctly:

- word-at-cursor must return the symbol/word fragment at the cursor position for a given input line, supporting common Clojure token characters (including namespaces like clojure.string/ and hyphenated names) and returning an empty string when the cursor is at a boundary with no word.
- Completion must work for namespaced vars and should not crash or return incorrect fragments when the cursor is in the middle of a token.

Reproduction examples:

1) Multi-line form evaluation:
- If the user enters a first line with an incomplete form like "(inc" and then a second line "1)", the REPL should evaluate the combined form "(inc\n1)" and print "2".
- If the user enters a complete form like "(+ 1 2 3)", it should immediately evaluate and print "6".

2) Interrupt handling:
- If the user begins an incomplete form and then triggers an interrupt, the REPL should not evaluate anything from the partial input and should return to a clean prompt state.

3) Word extraction for completions:
- Given an input line and cursor index, calling word-at-cursor should return the correct token fragment under the cursor (e.g. "clojure.str" when the cursor is within that fragment, or "str/j" for a namespaced var fragment), suitable for feeding into a completion engine.

Currently, at least one of these behaviors is incorrect: incomplete forms may be evaluated too early or not at all, interrupts may leave behind partial buffered input, and/or word-at-cursor returns the wrong fragment for completion, causing REPL completions to fail or behave inconsistently. Fix start-repl!/repl-with-line-reader integration so multi-line accumulation, interrupt/end-of-input behavior, and word-at-cursor/complete-form? semantics work together correctly.