Ecto currently generates invalid SQL when using `on_conflict: :replace_all` with schemas that define multiple fields pointing to the same database column via `:source`. In this situation, an upsert tries to assign the same column more than once, causing PostgreSQL to raise:

`** (Postgrex.Error) ERROR 42601 (syntax_error) multiple assignments to same column "full_name"`

This happens, for example, when a schema includes both a normal field and a legacy alias field mapped to the same column:

```elixir
schema "users" do
  field :email, :string
  field :full_name, :string
  field :legacy_full_name_field, :string, source: :full_name
  timestamps()
end

Repo.insert(%User{email: "user@ecto.test", full_name: "First Last"},
  conflict_target: [:email],
  on_conflict: :replace_all
)
```

The upsert should succeed without generating duplicate column assignments.

Add support for schema fields that can be explicitly marked as read-only (for example, `field :legacy_full_name_field, :string, source: :full_name, read_only: true`). Read-only fields must behave consistently across Ecto operations:

- Schema metadata must expose read-only fields as regular fields (they can be loaded and queried), but they must not be considered writable. `__schema__(:writable_fields)` must exclude read-only fields, while `__schema__(:fields)` and `__schema__(:query_fields)` must include them.
- Changesets must allow casting read-only fields (similar to virtual fields) so users can work with the value in-memory, but those fields must not be persisted on insert/update.
- `Repo.insert/2` and `Repo.update/2` must silently ignore read-only fields when building the write payload (like virtual fields), so they don’t produce duplicate writes or attempt to write generated columns.
- When `returning: true` (or returning is otherwise enabled), read-only fields should still be eligible to be returned and populated on the struct after inserts/updates.
- `on_conflict: :replace_all` must never attempt to update read-only fields; in particular it must not produce multiple assignments to the same underlying column when multiple schema fields share a `:source`.
- When users explicitly request replacing/updating specific fields during conflict handling (such as `{:replace, fields}` or conflict update expressions) and include a read-only field, Ecto should raise an error rather than silently writing it.
- `Repo.insert_all/3` must reject attempts to write read-only fields: if the provided header/fields include a read-only field (whether inserting rows as maps or inserting from a query), it should raise immediately.
- `update_all` must raise if a read-only field is used in the `:update` portion of the query.

After these changes, upserts with `on_conflict: :replace_all` must work even when schemas contain multiple fields mapped to the same database column (as long as the non-writable alias fields are marked read-only), and read-only fields should be loadable/queryable and optionally returned after writes but never written as part of inserts/updates/upserts.