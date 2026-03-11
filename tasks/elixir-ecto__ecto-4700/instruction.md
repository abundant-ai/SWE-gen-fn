`Ecto.Repo.insert_all/3` can raise an `ArgumentError` when using `on_conflict: {:replace_all_except, fields}` together with `conflict_target`, in schemas where the only non-primary-key field is also the conflict target.

A minimal reproduction is a schema with only `:id` (primary key) and `:other_field`, and an `insert_all` call that inserts/queries both `id` and `other_field` while using:

```elixir
Repo.insert_all(MySchema, query,
  on_conflict: {:replace_all_except, [:id]},
  conflict_target: :other_field
)
```

Current behavior: this raises

```
** (ArgumentError) empty list of fields to update, use the `:replace` option instead
```

This happens because the conflict resolution logic ends up with zero fields to update (the conflict target gets excluded from the set of replaceable fields), even though the user explicitly asked to replace all fields except `:id`.

Expected behavior: `insert_all/3` should not raise in this scenario. When `on_conflict` is `{:replace_all_except, ...}` and there are no non-excluded fields left after computing the replacement set, Ecto should treat it as a valid no-op update for conflicts (or otherwise allow the operation to proceed without error). In particular, the presence of a `conflict_target` should not force Ecto into an “empty list of fields to update” error for this edge case.

Additionally, support a `:replace_changed` option for `insert_all/3` conflict handling so callers can choose behavior that only updates columns that would actually change on conflict. This option must integrate with the `on_conflict` modes used by `insert_all/3` (including `{:replace_all_except, ...}`) and must avoid raising the above `ArgumentError` for the described case.