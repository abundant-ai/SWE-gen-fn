Elixir currently treats bitstrings and binaries as the same type in parts of the compiler/type analysis and protocol/type-related tooling. This causes incorrect behavior when code relies on the distinction that a binary is a bitstring whose size is a multiple of 8, while a general bitstring may have a non-byte-aligned size.

The type system and related components need to represent and propagate `bitstring()` and `binary()` as distinct types.

Problems that must be fixed:

When a pattern or type annotation specifically indicates a binary (for example, matching or constructing a value with `<<_::binary>>`), the inferred type should be `binary()` and not the more general `bitstring()`.

When a pattern or type annotation indicates a general bitstring (for example, matching with `<<_::bitstring>>` or using a segment size that can produce non-byte-aligned results), the inferred type should be `bitstring()` and not `binary()`.

Type refinements across matches must preserve and narrow correctly between these two types. For example, if a value starts as an unknown bitstring-like term and is later matched against `<<_::binary>>`, it should be refined to `binary()`; if it is matched against a bitstring constraint that does not guarantee byte alignment, it must not be refined to `binary()`.

Protocol dispatch/consolidation and any logic that selects implementations based on built-in types must correctly distinguish binaries from other bitstrings. A protocol implementation intended for binaries must not erroneously apply to non-binary bitstrings, and vice-versa. This includes ensuring that consolidated protocol metadata and lookup functions correctly encode and use this distinction.

Expected behavior examples:

- Matching a struct field with `<<_::binary>>` should treat that field as `binary()` for type inference and checking.
- Matching or constructing with a bitstring constraint that allows non-byte-aligned sizes should result in `bitstring()`.
- A value inferred as `binary()` should still be usable wherever a `bitstring()` is expected (since binary is a subset of bitstring), but not the other way around.

Fix the underlying type representation and all affected inference/refinement paths so that code using binary/bitstring-specific patterns produces correct inferred types and does not confuse protocol implementation selection.