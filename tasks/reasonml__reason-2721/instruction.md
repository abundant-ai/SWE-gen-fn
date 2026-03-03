Reason currently fails to compile code that uses Melange’s object-literal extension, reporting `Error: Uninterpreted extension 'bs.obj'.` This happens when writing JavaScript object literals using the extension form (previously `%bs.obj`), which is needed to build JS object values (often for interop types like `Js.t`) and for patterns like generating a default export object.

The compiler/formatter should recognize and correctly handle the Melange extension name `mel.obj` (i.e., `[%mel.obj {...}]`). Using `[%mel.obj { switch = "switch" }]` should be accepted and produce a valid JS object value suitable for coercion to an object type such as:

```ocaml
type marshalFields = < switch: string > Js.t
let testMarshalFields = ([%mel.obj { switch = "switch" }] : marshalFields)
```

Expected behavior: code containing `[%mel.obj { ... }]` compiles successfully, and the syntax is treated as the supported JS object-literal construct (including correct handling of record-like fields inside the extension payload).

Actual behavior: the extension is not interpreted correctly in some contexts, leading to an “Uninterpreted extension” compilation error (as seen with `bs.obj`), preventing common interop patterns like building configuration objects and default export objects.

Update the Reason toolchain so that `mel.obj` is a recognized/supported extension for JS object literals (replacing the legacy `bs.obj` expectation), and ensure formatting/printing round-trips this syntax correctly (e.g., `refmt` should output `[%mel.obj { ... }]` in the expected normalized form).