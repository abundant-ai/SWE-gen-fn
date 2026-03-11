Using `values/2` in an `Ecto.Query` currently requires passing a map/keyword list of field types (for example `%{num: :integer, text: :string}`), even when those types already exist in an Ecto schema. This makes it awkward to reuse existing schema definitions when building a values-list source.

`values/2` should also accept an Ecto schema module as its second argument and derive the field types from that schema. For example, given a schema module `Schema` with fields `:num` and `:text` defined as `:integer` and `:string`, the following should produce a query whose `from` source is a values-list source with the same type information as if the types map had been provided:

```elixir
values = [%{num: 1, text: "one"}, %{num: 2, text: "two"}]
query = from v in values(values, Schema)
```

The computed types must match the schema’s field types, and the resulting query source must be equivalent to providing the explicit types map.

Validation rules for `values/2` must continue to apply:

- When given an empty values list, it must raise `ArgumentError` with the message: `"must provide a non-empty list to values/2"`.
- `values/2` must ensure that the type for every field present in the values entries is declared. If any field in the values entries does not have a corresponding type, it must raise `ArgumentError` with the message: `"values/2 must declare the type for every field. The type was not given for field `FIELD`"`, where `FIELD` is the missing field.
  - This must work when the second argument is a schema module too. For example, if the values contain `%{not_a_field: 1}` and the schema has no such field, it must raise: `"values/2 must declare the type for every field. The type was not given for field `not_a_field`"`.
- Each entry in the values list must have the same set of fields. If any entry is missing a field present in others, it must raise `ArgumentError` with the message: `"each member of a values list must have the same fields. Missing field `FIELD` in MAP"` (with the missing field name and the inspected map that is missing it).

Overall, `values/2` should accept either a types map/keyword list or a schema module for its types argument, produce the same internal representation for the values-list source, and preserve existing error behavior and messages.