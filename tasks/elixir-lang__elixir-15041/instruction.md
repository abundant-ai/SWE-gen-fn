Type inference in Elixir does not currently refine types when a guard compares a value to a literal using equality/inequality operators. This causes the type checker to keep variables as overly broad (often `dynamic()`) even when a guard clearly restricts a variable to a specific literal (or excludes one).

When type-checking code that uses guards like `x == :foo`, `x != :foo`, `x === :foo`, or `x !== :foo`, the type system should infer and propagate the refined type information for `x` based on the comparison to the literal.

For example, in code that branches or matches based on a guard, `x == :foo` should refine `x` to the literal type `:foo` within the scope where the guard is known to hold. Conversely, `x != :foo` should refine `x` to “any value of the original type except `:foo`” when such a refinement is representable.

This refinement must work specifically for guards (not only for pattern matching), and it must integrate with existing refinement/propagation so that:

- If a variable is compared to an atom literal in a guard, the inferred type of the variable in the guarded branch becomes that atom literal.
- The refinement should compose with prior type knowledge. For instance, if `x` is already known to be an atom, `x == :foo` refines to `atom([:foo])` rather than a generic atom.
- The refinement must not “corrupt” variable information outside the guarded scope; only the branch where the guard holds should see the refined type.
- The behavior should be consistent for both strict and non-strict equality operators (`==`/`!=` and `===`/`!==`) when one side is a literal and the other side is a variable/expression whose type is being inferred.

Currently, code relying on such guards does not get the expected narrowing and remains too imprecise; implement the missing inference/refinement so guarded literal equality meaningfully narrows types and is propagated through subsequent expressions in the guarded branch.