When printing OCaml parsetrees in “source” form (e.g., via the `-dsource` output used by tooling), the pretty-printer currently chooses the `\#keyword` raw-identifier spelling for infix keyword operators such as `mod` and `lsl` in situations where OCaml syntax allows the parenthesized keyword-operator form `(mod)` / `(lsl)`.

This causes two problems:

1) Output is unnecessarily ugly and differs from standard surface syntax. In contexts where an operator is expected, `mod` and similar keyword operators should be emitted as `(mod)` rather than `\#mod`.

2) It reduces backward compatibility of generated code when targeting older OCaml parsers. Some downstream tools (notably code generators using recent pretty-printers to emit code intended to be parsed by older compiler versions) encounter update/regression issues because the pretty-printer emits `\#keyword` in places where older parsers/tools expect or more reliably handle `(keyword)` for infix keyword operators.

Fix the parsetree pretty-printer so that whenever an infix keyword operator is being printed in a context where the parenthesized operator form is syntactically valid, it preserves/uses that form, printing `(mod)`, `(lsl)`, etc., instead of `\#mod`, `\#lsl`.

This should be context-sensitive: `\#keyword` must still be used for true raw identifiers (e.g., value names, labels, object methods, polymorphic variant tags, type names) where the `(keyword)` operator form is not permitted or would change meaning. The change must only affect the printing of keyword operators in operator positions.

After the change, generated `-dsource` output should round-trip through parsing in the intended target versions, and code using raw identifiers such as `\#and`, `\#let`, `\#rec`, `\#mutable`, etc. must continue to print exactly as raw identifiers (i.e., not be accidentally converted into keyword-operator forms).