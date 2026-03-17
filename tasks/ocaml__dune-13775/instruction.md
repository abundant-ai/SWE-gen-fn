Boolean condition simplification for package expressions does not fully reduce expressions involving undefined variables when using the special operators `and_absorb_undefined_var` and `or_absorb_undefined_var`. These operators are intended to behave like logical `and`/`or` while treating undefined variables as absorbable in the same way that recent reduction rules already handle `and` and `or`.

Currently, complex conditional expressions produced during conversion/execution of opam package commands can remain unnecessarily nested and fail to simplify, especially when an undefined variable appears inside an `and_absorb_undefined_var`/`or_absorb_undefined_var` subexpression combined with constants like `true`/`false` and negations. This leads to incorrect or inconsistent selection of actions (e.g., choosing the wrong command branch) and incorrect behavior in cases where undefined variables should be absorbed away by these operators.

The simplifier must be updated so that `and_absorb_undefined_var` and `or_absorb_undefined_var` reduce further in the same spirit as normal `and` and `or` simplification:

- `and_absorb_undefined_var true X` should simplify to `X` (including when `X` contains undefined-variable references that are meant to be absorbed by this operator).
- `and_absorb_undefined_var false X` should simplify to `false`.
- `or_absorb_undefined_var false X` should simplify to `X`.
- `or_absorb_undefined_var true X` should simplify to `true`.

The behavior must also correctly handle nested compositions and negations so that repeated applications of these rules fully normalize the expression rather than leaving partially simplified forms.

This impacts both the expression-level simplification APIs used for package boolean language, including `Slang.simplify_blang`, and the higher-level evaluation that determines whether opam command filters like `{ madeup | false | installed | madeup2 }` and `{ ! (madeup & false & installed & madeup2) }` correctly collapse with undefined variables present.

After the fix:

- Simplifying boolean expressions involving `and_absorb_undefined_var`/`or_absorb_undefined_var` with constant left operands must produce the same reduced shapes that normal `and`/`or` would produce in equivalent situations.
- Executing converted opam command filters that contain disjunctions/conjunctions with some undefined variables should continue to succeed and choose the expected branches, while cases intended to be errors (e.g., disjunctions that are entirely undefined/false, or conjunctions that are entirely undefined/true) should still report errors consistently.