In PureScript, an instance declaration for a type class with members currently requires a `where` block implementing all class members. This makes it impossible to write a clean “unreachable” instance whose constraint includes `Prim.TypeError.Fail`, because such an instance can never be selected, yet the compiler still forces users to provide dead-code implementations for every member.

Update the compiler so that a type class instance whose context includes a `Prim.TypeError.Fail` constraint is allowed to have an empty body (i.e., omit the `where` section entirely), even when the class defines members. For example, the following should compile:

```purescript
import Prim.TypeError

class Foo t where
  foo :: t -> String
  bar :: Int -> t

instance fooInt :: Fail (Text "can't use this") => Foo Int
```

This relaxation should apply only when the instance is effectively unusable due to the `Fail` constraint; it should not weaken the existing rule about partial implementations. If an instance includes a `where` block, then it must still implement all class members. In particular, it must remain an error (with the existing `MissingClassMember` error) to define only some members and omit others, even if the instance has a `Fail ...` constraint. For example, an instance like this must still be rejected because `bar` is missing:

```purescript
import Prim.TypeError

class Foo t where
  foo :: t -> String
  bar :: Int -> t

instance fooInt :: Fail (Text "can't use this") => Foo Int where
  foo _ = "unreachable"
```

Expected behavior:
- Instances constrained by `Prim.TypeError.Fail` may omit `where` entirely and still typecheck.
- If a `where` is present, the compiler must continue to require a complete set of member implementations and report missing members using the existing missing-member error reporting.