Reason interface files (.rei) currently reject ppx annotations placed on signature let/val declarations using OCaml-style syntax. In OCaml, signatures can annotate values like:

```ocaml
val%nativeComponent foo : bar
```

In Reason, attempting the analogous signature form causes a parse error. For example, formatting/parsing this input fails:

```reason
let%nativeComponent foo: bar;
```

with an error like:

```
Line 1, characters 3-4:
Error: Syntax error
```

Instead, the formatter suggests rewriting to an attribute payload form such as:

```reason
[%%nativeComponent: let foo: bar]
```

This is inconsistent with how ppx annotations already work for implementation let-bindings (e.g., `let%ppx foo = ...`) and breaks parity with OCaml signatures.

Update the Reason parser/formatter so that ppx annotations on signature value declarations are accepted and round-trip formatted consistently. Specifically:

- In a .rei signature, `let%foo name: type;` should parse successfully.
- Formatting should preserve the `%foo` annotation in the output (it should not force rewriting into `[%%foo: ...]`).
- The same feature should work for `external` value declarations as well, so that both `external%foo bar: ...;` and `external%foo bar: ... = "...";` format correctly.

After the change, formatting a signature containing both attribute-payload forms and the new `let%foo ...` / `external%foo ...` forms should succeed without syntax errors, and the `let%foo foo: bar;` form should remain as `let%foo foo: bar;` in the formatted output.