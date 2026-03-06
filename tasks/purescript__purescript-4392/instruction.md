The compiler currently lacks (or incompletely supports) deriving `Foldable` and `Traversable` instances for user-defined algebraic data types. Add support for `derive instance Foldable ...` and `derive instance Traversable ...` so that valid data declarations can have these instances generated automatically, and invalid declarations fail with the correct errors.

Deriving `Foldable` must only work for type constructors of kind `Type -> Type`. If a user writes `derive instance Foldable Foo` where `Foo` has kind `Type` (no type parameter), or has a kind other than `Type -> Type` (for example, `Foo :: (Type -> Type) -> Type`), or has extra parameters such that the chosen head isn’t of kind `Type -> Type`, the compiler should reject it with the `KindsDoNotUnify` error while checking that the type has kind `Type -> Type`.

Deriving `Foldable` must also reject data types where the element type parameter is used in positions which cannot be folded. In particular, the final type variable (the element variable) must only appear as the last argument to type constructors in fields. If the element variable appears to the left of another type argument (e.g. in a field like `Tuple a Int`, or in a multi-parameter type application like `f a a` when the derived head fixes some parameters), the compiler should fail with `CannotDeriveInvalidConstructorArg` and an error message of the form:

"The type variable `a` must only be used as the last argument in a data type:"

and include the relevant source span for the offending `a` occurrence(s). If there are multiple invalid occurrences in a single constructor field/type, the compiler should report multiple `CannotDeriveInvalidConstructorArg` errors (i.e., deduplicate identical errors but still report distinct bad occurrences when appropriate).

If deriving would require a `Foldable` (or `Traversable`) instance for a type which cannot be resolved (for example, a constructor field contains a function type like `forall t. Show t => t -> a`, which would imply needing `Foldable (Function t)`), then deriving should fail with `NoInstanceFound` and include the unsolved wanted constraint in the message (e.g. `Data.Foldable.Foldable (Function t3)`), along with the usual note that the instance head contains unknown type variables.

Once implemented, users should be able to derive these classes for typical recursive and container-like fields, and they should get the precise failures above for the invalid examples:

```purescript
import Data.Foldable (class Foldable)

data Foo = Bar
derive instance Foldable Foo  -- should fail with KindsDoNotUnify


data Foo f = Bar (f Int)
derive instance Foldable Foo  -- should fail with KindsDoNotUnify


data Test a = Test (a -> Int)
derive instance Foldable Test -- should fail with CannotDeriveInvalidConstructorArg


data Test a = Test (Tuple a Int)
derive instance Foldable Test -- should fail with CannotDeriveInvalidConstructorArg

foreign import data Variant :: Row Type -> Type

data Test a = Test (Variant (left :: a, right :: Array a))
derive instance Foldable Test -- should fail with CannotDeriveInvalidConstructorArg twice (for both `a` occurrences)
```

In addition, implement the corresponding `Traversable` deriving so that it is consistent with `Foldable` deriving in terms of what shapes are accepted/rejected, and ensure the generated code behaves as a lawful traversal for supported types.