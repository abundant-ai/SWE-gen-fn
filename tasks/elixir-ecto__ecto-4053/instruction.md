When building association queries via `Ecto.assoc/3`, the query prefix handling is inconsistent for associations whose schemas do not define a `@schema_prefix`.

Currently, when `Ecto.assoc/3` is called with a struct whose schema defines a `@schema_prefix`, the generated association query does not reliably apply the struct’s prefix to the association target when the association schema has no prefix of its own. This leads to the association query being built with a missing/incorrect prefix.

The expected behavior is:

- If the owner struct has a schema prefix (for example, `@schema_prefix "owner_prefix"`), and you call `Ecto.assoc/3` for an association whose related schema does not define a prefix, the resulting association query must use the owner struct’s prefix.

  Example behavior:
  - Calling `Ecto.assoc(%OwnerSchema{id: 1}, :no_prefix_assoc)` should produce a query whose source prefix is "owner_prefix".
  - The same must hold when passing multiple owner structs: `Ecto.assoc([%OwnerSchema{id: 1}, %OwnerSchema{id: 2}], :no_prefix_assoc)` should also produce a query whose source prefix is "owner_prefix".

- If the association schema already defines its own `@schema_prefix`, that prefix must be preserved and must not be overridden by the owner struct’s prefix.

  Example behavior:
  - Calling `Ecto.assoc(%OwnerSchema{id: 1}, :prefixed_assoc)` should produce a query whose source prefix is the association schema’s prefix (for example, "assoc_prefix"), not the owner’s prefix.

- For chained associations (passing a list path), the owner struct’s prefix must be applied across the entire chain for any association schemas that do not define a prefix.

  Example behavior:
  - `Ecto.assoc(%OwnerSchema{id: 1}, [:no_prefix_assoc, :no_prefix_nested_assoc])` should result in both sources in the chain using "owner_prefix" when neither associated schema defines a prefix.

- If the caller passes an explicit `prefix:` option to `Ecto.assoc/3`, that option must take precedence over the owner struct’s prefix.

  Example behavior:
  - `Ecto.assoc(%OwnerSchema{id: 1}, :no_prefix_assoc, prefix: "prefix_opt")` should produce a query whose source prefix is "prefix_opt".

Implement or adjust the relevant logic in `Ecto.assoc/3` (and any internal helpers it relies on) so these prefix rules are consistently applied for single structs, lists of structs, and chained association paths. The resulting query’s `sources` entries must reflect the correct prefix selection rules above.