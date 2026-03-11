`field/2` currently behaves inconsistently depending on whether the field name is provided as an atom or a string. In queries, `field(x, :z)` is handled as expected, but `field(x, "z")` does not properly integrate with schema/type resolution and field source normalization.

When a schema-backed query uses `field/2` with a string field name, Ecto should treat the string name as referring to the same schema field as the corresponding atom. In particular, schema lookups like `__schema__(:type, field)` must correctly resolve the type even when `field` is a binary (string). Additionally, schema lookups like `__schema__(:field_source, field)` must normalize the field name so that downstream query planning/adapters receive a consistent representation (an atom field name) during normalization.

Expected behavior:
- `field(binding, "some_field")` should be accepted anywhere `field(binding, :some_field)` is accepted.
- Type inference and planning should work for string field names the same way as for atom field names (for example, a field defined as `:integer` should still be treated as `:integer` when referenced via its string name).
- Field source normalization should ensure that even if a field is referenced by string, internal normalized representation uses the atom field name so adapters do not need special handling for binaries.
- Query escaping should correctly represent string-based field access (e.g., `field(x, "z")`) as a field access expression using the string name, while still allowing schema/type resolution and planning to succeed.

Actual behavior:
- Using a string in `field/2` can fail to resolve schema metadata (type and/or source), leading to incorrect planning/type handling or runtime errors when building/planning queries that reference schema fields via string names.

Implement support so that schema metadata functions handle both atom and binary field identifiers for `:type` and `:field_source`, with proper normalization back to atoms during query normalization/planning.