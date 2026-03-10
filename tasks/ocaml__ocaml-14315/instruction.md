The OCaml compiler’s `-i-variance` option is intended to print inferred variance information (e.g. `+`, `-`, `!`) in interfaces produced by `ocamlc -i`/`ocamlopt -i`. It currently works for some type declarations, but it does not correctly handle variance printing for class-related declarations and for extension constructors.

When `-i-variance` is enabled, the printed interface should include the inferred variance markers for all relevant declared type parameters, including those that appear in class types/classes and in extension constructor declarations. Today, those constructs either omit variance information, print it inconsistently compared to regular type declarations, or fail to propagate the `-i-variance` behavior through the printing/inference pipeline.

Update the compiler so that:

- With `-i-variance`, inferred variance annotations are displayed for type parameters associated with class declarations and class types (e.g. in object/class type abbreviations where parameters can be inferred as covariant/contravariant/invariant).
- With `-i-variance`, inferred variance annotations are displayed for extension constructors (type extensions) in the same way they are for ordinary type declarations.
- The behavior remains consistent with existing `-i-variance` output for other type declarations: variance markers should only appear when the flag is enabled, and the markers should reflect the compiler’s principal/inferred variance results.

A user-visible way to observe the problem is that running `ocamlc -i -i-variance` on code that defines parameterized types and then uses them in signatures should print variance markers like `type +!'a t = ...` when appropriate. This should continue to work, and additionally it should now work for the same kinds of variance inference when the declarations involve classes/class types and extension constructors.

Also ensure the `-i-variance` option is described in the manpages so that users can discover what it does and where it applies (printing inferred variance in the `-i` output).