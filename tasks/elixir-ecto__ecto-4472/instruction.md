Ecto schemas currently support a `:read_only` field option, but it is not granular enough for workflows like inserts vs updates vs upserts. Introduce a new field option named `:writable` to replace `:read_only`, and make Ecto consistently respect it across schema metadata, query building, and write operations.

When defining a schema field, users should be able to write:

```elixir
schema "posts" do
  field :unwritable, :string, writable: :never
  field :non_updatable, :string, writable: :insert
end
```

The `:writable` option must accept exactly these values:

- `:always` (default) — the field can be written on both inserts and updates
- `:insert` — the field can be set on insert, but must not be written on update; it also must not be allowed to be written as part of upsert updates (i.e., it cannot be used in `on_conflict` update clauses)
- `:never` — the field must never be written (neither insert nor update)

Ecto must expose correct schema metadata derived from `:writable`:

- `__schema__(:insertable_fields)` must include fields with `writable: :always` and `writable: :insert`, and must exclude `writable: :never`.
- `__schema__(:updatable_fields)` must include only fields with `writable: :always`, and must exclude both `writable: :insert` and `writable: :never`.
- Queryable/loading behavior must remain unaffected; fields marked `writable: :never` or `writable: :insert` should still be usable in queries/selects like any normal (non-virtual) field.

Any internal query AST metadata that previously annotated field access with `read_only` should now use `writable` (for example, field access metadata should include something like `writable: :always` for normal fields).

Backwards behavior to fix: fields intended to be "insert-only" are currently treated as generally writable (or are only controllable via a boolean-like `:read_only`), which allows them to be updated or included in upsert update clauses. After this change, attempts to update a field declared with `writable: :insert` must not write it to the database and must not allow it to participate in update portions of upserts.

Additionally, `:read_only` should no longer be the supported schema field option; replace it with `:writable` throughout Ecto so users can rely on the new semantics consistently.