Reason/Refmt currently supports extension sugar on several top-level constructs (e.g., `let%foo`, `module%foo`, `external%foo`, `open%foo`), but does not correctly support the analogous extension sugar on type declarations. As a result, code using `type%foo ...` either fails to parse or is not preserved/pretty-printed correctly by `refmt`.

Implement support for extension sugar on type declarations so that `type%ext` behaves like other `%ext`-suffixed items and round-trips through formatting.

The formatter should accept and print the following forms:

```reason
type%foo t = int;
```

It should also continue to support extension sugar on type extensions (additions) and format them correctly, including multi-line variant additions:

```reason
type%x foo +=
  | Int;
```

Extension sugar should be handled consistently in both implementation (`.re`) and interface (`.rei`) syntax, including when used alongside other top-level items already supporting `%ext` (e.g., `let%foo`, `module%foo`, `external%foo`, `open%foo`).

Expected behavior when running `refmt` on inputs containing these constructs:
- `type%foo t = int;` is preserved and printed exactly in that sugared form.
- `type%x foo += Int;` is printed as a properly formatted type extension, using `+=` and `|` formatting when appropriate.
- No parse errors or syntax errors occur solely due to the presence of `type%...`.

Actual behavior to fix:
- `type%foo ...` is rejected or rewritten/printed incorrectly, preventing projects from using extension points on type declarations while still benefiting from formatting and round-tripping.