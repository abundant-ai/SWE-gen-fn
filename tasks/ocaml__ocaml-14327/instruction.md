In recent trunk versions, pattern matching involving GADTs/existentials regressed in two related ways: (1) the exhaustiveness/partial-match warning is spuriously triggered for functions that are actually total once the argument type is specialized by a GADT constructor, and (2) some previously-accepted patterns using `as` (as-patterns) and nested `|` (or-patterns) stop typechecking when the matched constructor introduces existentials.

This shows up with GADT-indexed variants where the function’s argument is polymorphic (or uses a more general index), but individual branches refine the index enough to make the match total for that refined type. For example, with:

```ocaml
type a
type b

type 'x test =
  | Gen of int
  | A : a -> a test
  | B : b -> b test

let f = function
  | Gen _ -> ()
  | A _ -> ()

let g = function
  | Gen _ -> ()
  | B _ -> ()
```

`f` and `g` should not be reported as partial matches merely because the other GADT constructor exists, since `A` and `B` refine the index and are not both possible for the same specialized input type in the relevant contexts. Similarly, when the function argument is explicitly specialized, a single-branch match should not warn as partial when the other constructor is impossible:

```ocaml
type a
type b

type 'x test =
  | A : a -> a test
  | B : b -> b test

let f : a test -> unit = function
  | A _ -> ()

let g : b test -> unit = function
  | B _ -> ()
```

Additionally, as-patterns should allow “retyping” (re-specializing) a bound name after passing through a pattern that introduces existentials, including when combined with nested or-patterns. Code like the following should typecheck and preserve the refined type for the `as`-bound variable:

```ocaml
type _ t =
  | Value_int of int
  | Value_snd : ('a, 'b option) result -> 'b t

let f (x : _ t) =
  match x with
  | (Value_int _ | Value_snd (Ok _ | Error None)) as y -> y
  | Value_snd (Error (Some _)) -> Value_snd (Error None)
```

Expected behavior:
- No spurious warning 8 (`partial-match`) in the GADT examples above when the missing cases are provably impossible due to GADT index refinement.
- Patterns of the form `(p1 | p2) as y` (including when `p1`/`p2` contain constructors with existential type parameters, and including nested or-patterns like `Value_snd (Ok _ | Error None)`) should typecheck.
- The `as`-bound variable (`y` above) must have the correctly re-specialized type that follows from the successful pattern match, so returning `y` from the branch is accepted with the function’s inferred/expected return type.

Actual behavior to fix:
- Trunk emits `partial-match` warnings for matches that should be exhaustive under GADT reasoning.
- Some combinations of `as`-patterns with existentials (especially under or-patterns / nested or-patterns) fail to typecheck, preventing previously-valid code from compiling.

Implement the necessary typing changes so that as-pattern retyping works in the presence of existentials and nested or-patterns, and so exhaustiveness/partial-match analysis is consistent with GADT-based impossibility of certain constructors in these refined contexts.