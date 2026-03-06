A regression in the PureScript compiler causes variables bound in one guard clause of a `case` alternative to incorrectly clash with variables bound in a different guard clause in the same alternative.

For example, compiling the following code fails even though each `z` should be scoped only to its corresponding guarded expression:

```purescript
data Foo = Foo Int | Bar Int

g :: Foo -> Int
g =
  case _ of
    a
        | Bar z <- a
        -> z
        | Foo z <- a
        -> z
        | otherwise
        -> 42
```

Current behavior (regressed in 0.15.3): the compiler reports an error such as:

```
Value z is undefined.

while inferring the type of z
in value declaration g
```

Renaming `z` in one of the guard clauses makes the error disappear, which indicates the compiler is incorrectly treating bindings from different guard clauses as sharing scope or interfering with each other.

Expected behavior: variables introduced by pattern guards (eg `Bar z <- a`, `Foo z <- a`) must be scoped only within the expression to the right of their corresponding `->` for that guard, and bindings from separate guard clauses must not conflict. The example above should compile without errors and evaluate `g (Bar 1) = 1`, `g (Foo 2) = 2`, and return `42` when neither guard matches.

Fix the compiler’s handling of guard-clause binding scopes so that repeated binder names across separate guards in the same `case` alternative are treated as distinct, and no longer produce undefined-variable or similar scope-related errors.