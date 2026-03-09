Artifact substitution placeholders are encoded into strings and later decoded/substituted back into concrete content. The current artifact substitution API has issues around placeholder encoding/decoding round-tripping and correct substitution when minimum placeholder lengths are involved.

When working with values like `Artifact_substitution.Repeat (n, s)`, calling `Artifact_substitution.encode` to produce a placeholder and then `Artifact_substitution.decode` on that placeholder should reliably return `Some <original value>`. This must hold for different `n` values (including 0) and for different payload strings, including empty strings, short strings, and long strings (e.g., length ~100).

Additionally, `Artifact_substitution.encode` supports an optional `~min_len` parameter that forces the encoded placeholder to be at least a certain length. The behavior must be:

- `Artifact_substitution.encode subst` produces an encoded placeholder string.
- Let `len = String.length (Artifact_substitution.encode subst)`.
- For a range of `min_len` values around `len` (both slightly smaller and slightly larger), `Artifact_substitution.encode subst ~min_len` must still decode via `Artifact_substitution.decode` back to `Some subst`.

Finally, when performing substitution into a larger string, the placeholder has an associated placeholder length `~len`, and the replacement must be encoded using `Artifact_substitution.encode_replacement ~len ~repl:<replacement_string>`. This replacement encoding must ensure the substituted output matches the expected naive behavior: scanning the input, detecting placeholders (e.g., those starting with a prefix like `"%%DUNE_PLACEHOLDER:"`), decoding them with `Artifact_substitution.decode`, and replacing them with the intended concrete replacement string (for `Repeat (n, s)`, the replacement is `s` repeated `n` times), while leaving all non-placeholder content unchanged.

Currently, at least one of these invariants is broken: either `encode`/`decode` fails to round-trip in some cases (especially when `~min_len` is used), or `encode_replacement` does not correctly respect the placeholder length contract, causing substitution outputs to differ from the expected result. Fix the artifact substitution implementation so that:

- `Artifact_substitution.encode`/`decode` round-trip for `Repeat (n, s)` across the described range of inputs.
- `~min_len` does not break decodability and still returns the original substitution value.
- Substitution using `encode_replacement` with the placeholder’s `~len` yields exactly the expected output for strings containing a mix of placeholders and ordinary text.