Reason interface/signature files do not currently support the extended external syntax form `external%foo ...` (the “external with extension” form). This syntax already works for structure/implementation items, but in signatures it fails to parse or cannot be pretty-printed correctly.

When an interface contains an external declaration with an extension marker, such as:

```reason
external%foo bar: string => string;
external%foo bar: int => int = "hello";
```

it should be accepted in signature context and formatted back out as valid Reason syntax.

Expected behavior:
- `external%foo` should be valid in signatures for both declaration-only externals (no `=` string payload) and externals that include the `= "..."` payload.
- Running the formatter on an interface containing these items should preserve the `%foo` extension marker and produce stable output that keeps the external as `external%foo ...`.
- In the `= "..."` case, the payload should be preserved and printed after the type as usual.

Actual behavior:
- The parser/formatter does not handle `external%foo` in signature items: it either rejects the syntax (parse error) or drops/mangles the `%foo` portion during formatting/printing.

Implement support so that `external%<extension>` works for signature externals in the same way it already works for non-signature externals.