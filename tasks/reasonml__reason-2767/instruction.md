Reason’s formatter/parser does not correctly handle externals using the extension form `external%foo` when they appear inside `module type` (signature) declarations.

Repro: define a module signature that contains an external with an extension name, e.g.

```reason
module type S = {
  external%bs "foo": int => int = "foo";
};
```

Expected behavior: `refmt` should successfully parse and print the code, preserving the `external%bs` (or any `external%<ext>` form) within the module type signature, producing valid, stable formatted output.

Actual behavior: `refmt` fails to handle this construct in `module type` contexts (either rejecting it with a parse error or emitting incorrect output that drops/misplaces the `%<ext>` part), even though the same `external%foo` form works in other contexts.

Fix `refmt` so that `external%<extension>` is accepted and correctly formatted when used as a signature item inside `module type { ... }`, including correct handling of its name string, type annotation, and external value binding syntax. The behavior should be consistent with how `external%<extension>` is treated outside of module type signatures, and repeated formatting should be idempotent.