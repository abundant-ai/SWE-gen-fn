The PureScript compiler crashes (internal error) when a type operator (an infix type alias) is used as part of a visible type application or otherwise appears in a type argument position.

For example, if a module imports an infix type alias like `type (/\)` (e.g. for `Tuple`), then using it in a visible type application such as:

```purescript
someVTA :: forall @a. String
someVTA = "some VTA"

main = someVTA @(Int /\ Int)
```

can cause the compiler to fail with an internal error similar to:

```
An internal error occurred during compilation: inferKind: Unimplemented case
String Data.Tuple.Nested./\ Maybe String
```

Instead of crashing, compilation should succeed for valid programs, or (if some form is unsupported) fail with a normal, user-facing type/kind error—never an internal error.

The compiler needs to correctly handle type operators during the desugaring/traversal that processes types involved in visible type applications and nested type AST structures. The following situations must compile without an internal error:

- Applying a function using a visible type application whose argument is a type expression containing a type operator, e.g. `singleArgument @(Int /\ Number)`.
- Multiple visible type applications are left-associative and may nest, e.g. `multiArgument @(Int /\ Number) @(Number /\ Int)`.
- Type applications may appear nested inside other expressions/type constructors, e.g. `Just @(Int /\ Number) (...)` inside an array.
- A type synonym used as a type argument should work, e.g. `type InSynonym = Int /\ Number` and then `singleArgument @InSynonym`.
- A type operator itself can be used as a type argument (not applied), e.g. `Proxy @(/\)`.

After the fix, these programs should compile cleanly and no longer trigger `inferKind: Unimplemented case` (or any other internal compiler error) when type operators appear in type argument positions.