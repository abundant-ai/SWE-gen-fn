When converting typed AST back to the surface AST via compiler-libs, module-qualified record patterns are not preserved correctly. In particular, a qualified record pattern like `M.{ x }` (a record pattern scoped to module `M`) can be untyped/printed as an unqualified record pattern `{ x }`. This loses the module scoping information and can lead to downstream typechecking failures such as `Unbound record field x` when the printed code is parsed/typechecked again outside of the intended module scope.

Reproduction example:
```ocaml
let module M = struct type t = { x : int } end in
fun x -> let M.{ x } = M.{ x } in x
```
If you parse and type this expression, then call `Untypeast.untype_expression` on the typed tree and print it with `Pprintast.expression`, the printed code must retain the qualification of the record pattern rather than dropping it. The pattern `M.{ x }` should remain qualified in the untyped representation/pretty-printed output (or be rewritten into an equivalent form that preserves the `M` scope), so that re-parsing/re-typechecking the printed program does not trigger record-field scope errors.

The issue is specifically about handling the pattern form represented in the typed AST as an “open” pattern (corresponding to `Tpat_open`). `Untypeast` currently fails to handle this case correctly in patterns, causing the printed pattern to appear as if it were unqualified. Update `Untypeast` so that `Tpat_open` patterns are untyped in a way that preserves the module path/qualification semantics for record patterns like `M.{ x }`, ensuring the pretty-printed result is semantically equivalent and does not produce `Unbound record field` errors when used independently.