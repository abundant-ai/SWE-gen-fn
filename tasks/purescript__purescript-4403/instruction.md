Decoding JSON into `Qualified` fails on JSON produced by PureScript versions prior to v0.15.2. Historically, `Qualified` values were encoded as a 2-element JSON array where the first element could be `null` to represent an unqualified name, for example:

```haskell
encode (Qualified Nothing "foo") == [null, "foo"]
encode (Qualified (Just (ModuleName "A")) "bar") == ["A", "bar"]
```

After changes to `Qualified`, the JSON representation no longer includes `null` in newly encoded output. However, for backwards compatibility, the `FromJSON` instance for `Qualified` still needs to accept the legacy form where the qualifier position is `null`.

Currently, when parsing legacy JSON like `[null, "foo"]` into a `Qualified`, decoding fails (or produces the wrong result), which breaks consumers that need to read previously generated JSON (e.g., older published package metadata).

Update the `FromJSON` instance for `Qualified` so that it accepts both:

- the current JSON representation used by newer versions, and
- the legacy representation where the first array element may be `null`.

When the decoder encounters the legacy `null` qualifier, it must interpret it as `Qualified ByNullSourcePos` (i.e., treat `null` as the specific “null qualifier” case rather than rejecting it).

Decoding should continue to work for the non-null legacy case `["A", "bar"]`, producing the same `Qualified` result as before, and it must not break decoding of the new-format JSON output.