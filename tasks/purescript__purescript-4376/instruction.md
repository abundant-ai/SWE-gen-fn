PureScript fails to fully infer types in some expressions involving visible type application (VTA) and records, leaving an unexpected polymorphic type (a remaining `forall`) where the expression should be monomorphic enough for downstream constraint solving.

A minimal example is a function which uses VTA to select a type-level string and returns a reflected runtime value:

```purescript
reflect :: forall @t v. Reflectable t v => v
reflect = reflectType (Proxy @t)

use :: String
use = show { asdf: reflect @"asdf" }
```

Expected behavior: this should compile, and `use` should evaluate to something like `{ asdf: "asdf" }`.

Actual behavior: the compiler does not infer the field value’s type precisely inside the record; it leaves a polymorphic `forall` in the inferred type. That prevents other typeclass constraints which require more concrete types (notably row/type-level operations such as `RowToList` and `Nub`, and similar constraint solving which depends on record field types) from being solved.

A key symptom is that adding any extra argument to the function (e.g. changing `reflect` to take `Unit -> v` and calling it with `unit`) makes the problem disappear, indicating an issue with when/where generalization/monomorphization happens for such expressions.

In addition, data constructors should infer to their “true” polymorphic types directly, without requiring an extra generalization step. For example, querying the type of the `Nothing` constructor should yield:

```purescript
forall (a :: Type). Maybe a
```

and using constructors in records and record updates should not leave behind generalized/unspecialized types that break subsequent typeclass solving. In particular:

- A top-level binding `value = Nothing` should infer `forall a. Maybe a`.
- Record updates like `_ { a = Nothing }` should produce a result whose field type is properly monomorphized to match the input record field type.
- Combining records containing constructor values (e.g. using a `Union` constraint to compute a combined row) should allow the relevant constraints to solve; it should not fail due to either side remaining insufficiently monomorphized.

Fix the compiler’s inference/monomorphization timing so that constructor expressions and VTA-dependent expressions inside records do not get prematurely generalized in a way that leaves `forall`s in places that should be specialized, and so that downstream row/typeclass constraint solving succeeds.