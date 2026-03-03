Reason currently rejects OCaml-style Unicode escape sequences of the form `\u{hex}` inside string literals, emitting `Warning 14: illegal backslash escape in string.`. This prevents writing code like:

```reason
let oghamSpace = "\u{1680}";
```

Add support for `\u{hex}` escapes in Reason string literals so that they are accepted by the parser/lexer and preserved by formatting.

When formatting Reason code containing Unicode escapes, the formatter should output the escape in canonical form (i.e., it should keep `"\u{...}"` as a unicode escape rather than rewriting it or rejecting it). This should work both for a single escape and for multiple escapes concatenated in one string.

When the Reason source is translated to OCaml and compiled, `\u{hex}` must be interpreted as the Unicode scalar value specified by the hexadecimal digits and encoded into the resulting string as UTF-8 bytes. For example:

- `"\u{1F42B}"` should compile to a string whose runtime printed value is `🐫`.
- `"\u{0000E9}"` should compile to a string containing `é`.
- `"\u{10FFFF}"` should compile to the UTF-8 encoding of U+10FFFF.

The escape should accept 1 to 6 hexadecimal digits inside the braces (including leading zeros), e.g. `\u{0}`, `\u{00}`, `\u{000}`, `\u{000000}`, `\u{0000E9}`.

It must correctly handle multiple escapes in a single string, e.g. `"\u{1F42B}\u{1F42B}\u{1F42B}"`, producing the corresponding repeated characters at runtime.

The new escape handling must not treat occurrences inside comments as string escapes; unicode-escape-like text inside comments should remain untouched and should not affect parsing/formatting.