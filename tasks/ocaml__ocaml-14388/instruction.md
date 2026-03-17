OCaml currently accepts the construct `let rec (module M : S) = e1 in e2` (and related forms of recursive bindings where the left-hand side is a first-class module unpack pattern). This is irregular because `let rec` is intended to allow only “variable-like” left-hand sides (variables and variable patterns with type annotations), rejecting other patterns.

The problem is that the typechecker still treats `(module M : S)` as an allowable left-hand side in a recursive `let rec` binding, so code like:

```ocaml
module type S = sig val f : int -> int end

let rec (module M : S) =
  (module struct
    let f n = if n <= 0 then 1 else n * M.f (n - 1)
  end : S)
in
M.f 5
```

is currently accepted (or at least not rejected with the correct error), even though it is not a variable pattern.

Expected behavior: any `let rec` binding whose left-hand side is not a variable-like pattern must be rejected consistently, including first-class module unpack patterns. In particular, `let rec (module M : S) = ...` must be rejected with the same error used for other non-variable patterns:

`Error: Only variables are allowed as left-hand side of "let rec"`

Actual behavior: the compiler allows recursive first-class module patterns in `let rec`, leading to inconsistent pattern validation and extra special-case typing behavior.

Implement the change so that pattern validation for `let rec` treats module unpack patterns (`(module ...)`) as invalid left-hand sides, both for single recursive bindings and for grouped recursive bindings (`let rec ... and ...`). The restriction should apply regardless of whether the pattern is annotated (e.g. `(module M : S)`), and should behave consistently in toplevel and expression `let rec ... in ...` forms.

As a result, code that previously typechecked using `let rec (module ...)` should now fail early with the above error, while ordinary variable-like recursive bindings (including annotated variables such as `let rec (x : int) = ...`) must continue to work unchanged.