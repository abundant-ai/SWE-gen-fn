Reason syntax currently lacks support for “quoted extensions”, a pure-syntax feature available in upstream OCaml. In OCaml, an extension node can be written using a quoted payload, e.g. `{%raw||}` (and other delimiter forms), and it is treated as an extension payload string without requiring the explicit AST form.

In Reason, trying to use this quoted-extension form should work but currently does not: the parser rejects the syntax (or does not round-trip correctly through formatting), forcing users to write only the explicit bracket form such as `[%raw{||}]`.

Implement support for quoted extensions in the Reason toolchain so that quoted extension syntax is accepted and preserved/normalized consistently.

Concretely:
- The parser should accept extension constructs written with the quoted form (the OCaml-style `{%name ...}` / `{%name||...||}`-style quoting) and produce the same AST as the equivalent bracketed extension form (e.g. `[%raw{||}]`).
- The formatter (`refmt`) must be able to format code containing quoted extensions without errors and must output a stable, valid representation. Quoted extension usage should round-trip deterministically (parsing then printing then parsing again yields equivalent output/AST).
- This must work in the same places existing extensions work, including:
  - structure items (e.g. extension items at top level),
  - expressions (including within blocks/sequences),
  - bindings using `let%ext`,
  - control-flow forms using extension sugar like `if%ext ...`, `switch%ext ...`, `try%ext ...`, `for%ext ...`, `while%ext ...`, and `fun%ext ...`,
  - nested/stacked extensions (e.g. an extension wrapping another extension).

Example expectation: writing `{%raw||}` should be treated equivalently to `[%raw{||}]` (same extension name and quoted payload semantics), and running `refmt` on a file using these forms should succeed and produce consistently formatted output.