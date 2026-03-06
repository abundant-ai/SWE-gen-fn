Typed hole diagnostics can include repeated entries in their “in the following context” section and can also cause duplicated suggestions, due to redundant entries being added to the type-checking environment.

Reproduction example:

```purescript
module Main where

data F a = F ((a -> Int) -> Int)

map :: forall a b. a -> (a -> b) -> F a -> F b
map a f (F g) = ?help
```

Current behavior: the compiler reports `HoleInferredType` for `?help`, but the printed context includes duplicates (for example, `a :: ...` and `f :: ...` appear more than once), and suggestion lists can contain repeated candidates. This duplication should not happen; each in-scope name should appear at most once in the hole’s context/suggestion output.

Expected behavior: when the compiler emits a `HoleInferredType` error, the “in the following context” section should not repeat bindings, and the “You could substitute the hole with one of these values:” list should not contain duplicates.

The fix should ensure that adding multiple equations/clauses (e.g., two branches of the same function, each containing `?help`) does not cause the printed per-hole context to accumulate duplicated entries. For example, for a function like:

```purescript
data F = X | Y

f :: forall a. F -> a -> a
f X b = ?help
f Y b = ?help
```

each reported hole error should list `b :: a0` exactly once in its context and suggestions, not repeated.

No changes are required to the error type itself (`HoleInferredType`), only to how the environment/context used for hole suggestions is collected/printed so that redundant entries are eliminated.