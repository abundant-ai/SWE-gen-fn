When using visible type application (VTA) syntax with type wildcards, the compiler incorrectly emits a `WildcardInferredType` warning even though the wildcard is intentional and should be ignored in this context.

Reproduction:

```purescript
f :: forall @a. a -> a
f = identity

test1 :: { x :: Int }
test1 = f @{ x :: _ } { x: 42 }
```

Current behavior: compiling this code produces a warning of the form:

```
Wildcard type definition has the inferred type

    Int

in value declaration test1
PureScript(WildcardInferredType)
```

Expected behavior: no `WildcardInferredType` warning should be produced when `_` appears inside a visible type application (e.g. `@{ x :: _ }`).

This should also work for more complex VTAs where multiple wildcards appear under type-level constructs such as constraints and function arrows. For example, code like:

```purescript
class Foo :: Type -> Type -> Type -> Constraint
class Foo a b c | a -> b c where
  fooMember :: a -> b

wrap :: forall @a. Array a -> Array (Array a)
wrap as = [as]

arrFooMember :: forall c. Array (Foo Int Boolean c => Int -> Boolean)
arrFooMember = [fooMember]

test2 :: forall c. Array (Array (Foo Int Boolean c => Int -> Boolean))
test2 = wrap @(Foo Int Boolean _ => _) arrFooMember
```

Expected behavior: neither wildcard in the visible type application `@(Foo Int Boolean _ => _)` should trigger a `WildcardInferredType` warning.

Implement the fix so that wildcards appearing within visible type applications are treated as ignored wildcards (i.e., they do not participate in the wildcard-inferred-type warning mechanism), while keeping existing wildcard warnings in other contexts unchanged.