PureScript 0.15.3 has a regression in `case` expressions with multiple guard clauses that use pattern guards binding the same variable name. When two different guard clauses bind the same name (e.g. both bind `z`), the compiler incorrectly reports the name as undefined while typechecking the guard result expression.

Reproduction:

```purescript
data Foo = Foo Int | Bar Int

g :: Foo -> Int
g =
  case _ of
    a
      | Bar z <- a -> z
      | Foo z <- a -> z
      | otherwise -> 42
```

Actual behavior: compiling this code fails with an error like:

```
Value z is undefined.

while inferring the type of z
in value declaration g
```

Workaround: renaming `z` in one of the guard clauses makes the error disappear.

Expected behavior: no error. Variables bound by a pattern guard must be scoped only to the corresponding guard’s right-hand-side expression, and bindings from one guard clause must not conflict with or affect bindings from other guard clauses in the same `case` alternative. In other words, each guard clause should have its own independent binder scope for names introduced by its pattern guards.

Also ensure this scoping behavior holds for pattern guards that bind identifiers which coincide with other in-scope names (for example, binding a name like `fold` in a pattern guard and then using `fold` in subsequent expressions should refer to the correct binding according to guard/expression scoping rules, without leaking or clashing across guards).