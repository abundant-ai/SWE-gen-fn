When building queries that use late-bound named bindings, Ecto is not respecting schema field types for `as/1`, `parent_as/1`, and `field(as(...), ...)` / `field(parent_as(...), ...)`. Instead, these expressions are being assigned the type `:any`, which prevents correct type checking and casting.

This shows up when using named bindings to reference fields in `where`, `join` conditions, or other expressions where values are cast based on field type. For example, if a schema field is declared as `:binary` (or any non-integer type), comparing it against an integer should fail to cast, but currently the comparison can incorrectly proceed because the field’s type was treated as `:any`. Likewise, if `parent_as/1` is used to reference a field that does not exist on the parent schema, Ecto should raise an error about the unknown field, but currently it may not raise because it never attempts to look up the field type.

Fix the query planning/type inference so that:

- `as/1` and `parent_as/1` bindings carry the correct schema/type metadata, rather than defaulting to `:any`.
- `field(as(binding), field_name)` and `field(parent_as(binding), field_name)` resolve `field_name` against the schema associated with that binding and use the actual Ecto type for casting and validation.
- If a referenced field does not exist on the schema for that binding, an appropriate error is raised (instead of silently treating it as `:any`).
- Casting behavior uses the resolved field type, so invalid comparisons (e.g., comparing a `:binary` field to an integer literal) correctly fail casting.

Example scenario illustrating expected behavior:

```elixir
from p in Post,
  as: :post,
  where: field(as(:post), :code) == ^123
```

If `Post.code` is a `:binary` field, Ecto should not treat `field(as(:post), :code)` as `:any`; it should treat it as `:binary` and the comparison against `123` should fail to cast (or raise a casting error) rather than being accepted.

Similarly, for a parent query:

```elixir
from c in Comment,
  join: p in assoc(c, :post),
  as: :post,
  where: field(parent_as(:post), :deleted) == true
```

If the `Post` schema has no `:deleted` field, Ecto should raise an error indicating the field does not exist, rather than accepting the expression due to `:any` typing.