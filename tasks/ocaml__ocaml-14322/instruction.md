The compiler currently contains leftover logic intended to support an old internal transformation of constrained patterns `(x : t)` into `(_ as x : t)`. Since the compiler no longer performs this transformation, the remaining special-case handling is both unnecessary and can lead to incorrect acceptance or confusing behavior around constrained patterns, especially in `let rec` bindings.

The type-checker should treat constrained patterns `(p : t)` directly, without relying on any fallback behavior that assumes an implicit `as`-pattern wrapper. In particular, recursive bindings must reject recursive definitions where recursion is only made possible through an aliasing pattern like `(_ as x)`.

Reproduction:

```ocaml
let rec (_ as x) = fun () -> x ()
```

This should be rejected by the type-checker (this form was never meant to be supported), because the recursive identifier is introduced only via an aliasing pattern and should not be allowed to define the recursive value.

At the same time, a directly constrained identifier pattern in a recursive binding must still be accepted:

```ocaml
let rec (x : unit -> _) = fun () -> x ()
```

Expected behavior:
- Constrained patterns `(p : t)` are type-checked without any legacy assumptions that they were rewritten into `(_ as ... : ...)`.
- `let rec (_ as x) = ...` is rejected when it attempts to define a recursive identifier through an alias pattern.
- `let rec (x : unit -> _) = ...` remains accepted and continues to type-check.

Actual behavior to fix:
- The compiler still has legacy handling related to the removed rewrite, which makes it accept the unsupported recursive aliasing pattern case or otherwise mishandles constrained patterns.

Update the type-checking logic so that the unsupported recursive aliasing case is forbidden, while preserving acceptance of properly constrained identifier patterns in recursive definitions.