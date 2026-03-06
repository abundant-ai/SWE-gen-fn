PureScript’s exhaustiveness checker fails to account for pattern matches that occur inside case guards, which can let non-exhaustive matches compile successfully and then crash at runtime.

For example, given:

```purescript
data Sound = Moo | Quack | Bark

type Animal = { sound :: Sound }

animalFunc :: Array Animal -> Unit
animalFunc animals
  | Just { sound } <- animals # Array.find \{ sound: Moo } -> true = unit
  | otherwise = unit
```

This currently compiles, but calling `animalFunc` with an `Animal` whose `sound` is `Quack` or `Bark` can lead to an unhandled runtime pattern-match exception, because the compiler did not detect that the guard introduces a match which is not total over `Sound`.

The compiler should instead reject this program during compilation with an exhaustiveness error for the implicit case analysis introduced by the guard pattern. The error should report that a case expression cannot be determined to cover all inputs and should list the missing cases required to cover all inputs, specifically that `{ sound: Quack }` and `{ sound: Bark }` are not handled. The diagnostic should also mention the usual alternative of adding a `Partial` constraint to the enclosing type when appropriate.

The same issue should be handled for other guard forms that introduce patterns, such as:

```purescript
animalFunc :: Animal -> Boolean
animalFunc animal
  | (\{ sound: Moo } -> true) $ animal = true
  | otherwise = false
```

and

```purescript
animalFunc :: Animal -> Boolean
animalFunc animal
  | (let { sound: Moo } = animal in true) = true
  | otherwise = false
```

Implement the fix so that `checkExhaustiveExpr` (and the overall exhaustiveness checking pass) properly traverses expressions appearing in guards and accounts for any pattern matches they introduce, ensuring these programs fail to compile rather than producing runtime match failures.