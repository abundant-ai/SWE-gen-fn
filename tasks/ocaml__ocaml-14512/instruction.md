Warning 16 ("unerasable-optional-argument") is currently being reported incorrectly (and inconsistently) in several typing scenarios, including a 5.5 regression involving first-class modules and GADTs, and a missed-warning case caused by direction-sensitive / prematurely-run checking.

1) Regression: warning raised even though the optional argument is erasable due to a following argument

The compiler warns on an optional argument even when it is followed by a non-optional argument that forces the function to be applied in a way that keeps the optional argument erasable. For example, compiling this code with warning 16 enabled:

```ocaml
module type SHOW = sig
  type t
  val show : t -> string
end

type 'a t = A : {x : string option; show : 'a -> string} -> 'a t

let test (type a) ?x (module M : SHOW with type t = a) =
  A {x; show = M.show}
```

currently produces:

```
Warning 16 [unerasable-optional-argument]: this optional argument cannot be erased.
```

This warning should not be emitted here; the presence of the first-class module argument after `?x` means `?x` is not in the problematic “trailing optional argument” position that makes it unerasable. This behavior is a regression compared to OCaml 5.4.

2) Missed warning: unerasable optional argument not detected due to checking too early / direction sensitivity

There are cases where a function ends up inferred with an unerasable optional argument, but no warning is emitted because the check happens before type inference for the surrounding definition has stabilized. For example:

```ocaml
let baz y =
  let foo ?x = y in
  ignore (y : unit);
  foo
```

Here, `foo` ends up with a type like `?x:'a -> unit` (an unerasable optional argument because it is the final argument of the function type), and warning 16 should be reported at the `?x` binder. Currently, this warning may be missed depending on inference order.

What needs to be implemented:

- Adjust the warning-16 detection so it is based on the final inferred type of the defined value/class after type inference for the relevant toplevel phrase (or equivalent compilation unit fragment) has completed, rather than performing the check too early in a way that depends on inference direction.
- Ensure the check correctly identifies when an optional argument is truly unerasable (e.g., functions/classes whose final type begins with an optional parameter and has no required argument afterward), and does not flag optional arguments that are followed by required arguments (including first-class module arguments).
- Preserve existing behavior for cases where warning 16 is legitimately expected, such as:
  - `let foo ?x = ()` should warn.
  - `let foo ?x ~y = ()` should warn.
  - `class bar ?x = object end` should warn.
  - Definitions where the optional argument is followed by `()` (e.g. `let foo ?x () = ()`) should not warn.
- The warning should still be able to appear even if the surrounding expression later triggers a type error (i.e., emitting warning 16 should not be suppressed just because a type error is reported afterward).

The goal is that OCaml 5.5 no longer emits warning 16 for the first-class-module/GADT example above, and does emit warning 16 reliably for definitions that ultimately infer an unerasable optional argument type like `?x:'a -> ...` without required parameters following it.