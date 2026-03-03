`refmt` does not currently accept extension attributes on `external` declarations, even though the same extension syntax works for other structure items like `let%foo`.

Reproduction:

```bash
$ echo "let%foo bar = \"\";" | refmt
let%foo bar = "";

$ echo "external%foo bar : int = \"\";" | refmt
Line 1, characters 8-9:
Error: Syntax error
```

In OCaml tooling, the analogous construct is valid and formats without error:

```bash
$ echo "external%foo bar : int = \"\"" | ocamlformat - --impl
external%foo bar : int = ""
```

`refmt` should parse and format `external` declarations that carry an extension attribute immediately after the `external` keyword (e.g. `external%foo ...`). The formatter should round-trip this syntax without raising a syntax error, preserving the extension name and producing a normalized output like:

```reason
external%foo bar : int = "";
```

This should work consistently anywhere an `external` declaration is valid at the structure level, and it should not regress existing extension-sugar handling for other constructs (e.g. `let%extend`, `if%extend`, `switch%extend`, `try%extend`, `fun%extend`, etc.).