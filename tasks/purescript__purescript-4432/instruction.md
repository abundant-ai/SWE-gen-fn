Deriving `Functor` for certain data types fails incorrectly when the instance head uses a different type variable name than the corresponding parameter name in the data declaration.

Given a type like:

```purescript
data TypedCache :: (Type -> Type) -> Type -> Type
data TypedCache key a = Get (key a)

derive instance (Functor k) => Functor (TypedCache k)
```

this should compile, but currently fails with an error like:

```
CannotDeriveInvalidConstructorArg
One or more type variables are in positions that prevent Functor from being derived.
...
data TypedCache key a = Get (key a)
                               ^
```

The failure is name-sensitive: renaming the instance head variable from `k` to `key` makes it compile, even though the two are alpha-equivalent and should behave identically. This indicates the deriving machinery is incorrectly associating constraints/instance requirements using the type variable names from the data constructor declaration (e.g. `key`) rather than the type variables as bound/used in the derive instance head (e.g. `k`).

The same underlying bug also shows up when deriving through a type constructor applied to a type variable, e.g. this should compile without requiring any extra, unrelated constraints:

```purescript
import Data.Const (Const)

data TypedCache :: (Type -> Type) -> Type -> Type
data TypedCache key a = Get (key a)

derive instance Functor (TypedCache (Const k))
```

Expected behavior: `derive instance` should be alpha-equivalence-safe. Changing type variable names in the derive instance head must not affect whether deriving succeeds. In particular, `Functor` deriving should correctly recognize that `Get (key a)` corresponds to the instance head parameter (e.g. `k`) and should only require `Functor k` (or the appropriate inferred constraint) based on the instance head type, not based on the original binder name in the data declaration.

Actual behavior: deriving fails unless a constraint is in scope for the data declaration’s parameter name (e.g. `Functor key`), even when that name does not appear in the instance head. This can also lead to situations where adding such a redundant constraint makes deriving succeed but introduces ambiguity that prevents using `map` with the derived instance.

Fix the compiler’s instance-deriving/constraint-resolution logic so that when deriving `Functor` (and related deriving that relies on instance lookup), any internal checks for required instances/dictionaries are performed against the type variables as represented in the instance head after proper renaming/substitution, not by matching on binder names from constructor declarations. The resulting behavior must allow the examples above to compile and be usable without requiring a spurious `Functor key` constraint.