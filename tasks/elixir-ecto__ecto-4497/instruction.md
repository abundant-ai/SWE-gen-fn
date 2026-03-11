Ecto currently assumes the `:prefix` option (and schema-level `@schema_prefix`) is a binary/string and raises or rejects other types. This became stricter in Ecto 3.12, breaking adapters that use a non-string prefix value (for example, an adapter that wants to pass a tenant handle/opaque term like `{:erlfdb_tenant, reference()}` as the prefix).

When building queries with `Ecto.Query` and when using schemas with `use Ecto.Schema`, `:prefix` should be allowed to be any Elixir term as long as it is provided via interpolation at runtime. The compile-time query macros should still only accept string literals for `:prefix` when given as a literal, but should accept `:prefix` values of any type when provided as an interpolated value (for example `prefix: ^tenant` where `tenant` can be a map, tuple, struct, etc.).

Schema modules should also be able to define `@schema_prefix` as a non-string term (for example, `@schema_prefix %{key: :private}`) without raising and without being coerced into a binary. The prefix term must be preserved in schema metadata and carried through repo operations so that adapters receive exactly the same term that was configured.

Expected behavior examples:

```elixir
# Query-time prefix should allow arbitrary terms via interpolation
tenant = {:erlfdb_tenant, make_ref()}
q = Ecto.Query.from(p in "posts", prefix: ^tenant)
# should compile and keep the prefix term

# Schema-time prefix should allow non-string terms
defmodule MySchemaWithNonStringPrefix do
  use Ecto.Schema
  @schema_prefix %{key: :private}
  schema "my_schema" do
    field :x, :string
  end
end
# should compile, and MySchemaWithNonStringPrefix.__schema__(:prefix) should return %{key: :private}
```

Actual behavior: providing a non-binary prefix (either through `:prefix` or `@schema_prefix`) causes compilation errors in query building and/or schema compilation, or raises due to internal validation expecting a binary.

Fix Ecto so that non-string prefixes are supported end-to-end (query building, schema metadata, and repo operations) while keeping the restriction that compile-time query literals for prefix must still be string literals (interpolated values can be any type).