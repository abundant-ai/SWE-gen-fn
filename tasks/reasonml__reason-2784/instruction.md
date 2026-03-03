Reason syntax currently does not consistently support extension application on `open` statements, particularly the form `open%foo Bar` and the combination of the “open bang” modifier with an extension payload: `open! %foo Bar`.

When code containing these constructs is formatted with `refmt`, one of the following problems occurs depending on the exact input: the extension is not parsed/printed correctly (it may be dropped or rearranged), or the formatter fails to round-trip the syntax.

`refmt` should fully support parsing and printing extension applications on `open` so that these forms round-trip and are emitted in a stable, canonical layout:

- `open%foo Bar;` must be accepted and printed back as `open%foo Bar;` (no loss of `%foo`, no rewriting into a different construct).
- `open! %foo Bar;` must be accepted and printed back preserving both the `!` modifier and the `%foo` extension, with spacing exactly as shown: `open! %foo Bar;`.

The implementation should ensure that `open` statements support the same extension handling as other extended constructs (e.g., `let%foo`, `module%foo`, `external%foo`), including correct AST representation so that the pretty-printer can reproduce the syntax faithfully.

Example input that must format without errors and round-trip:

```reason
open%foo Bar;
open! %foo Bar;
```

Expected formatted output is identical to the above (including the space between `!` and `%foo` in the second form).