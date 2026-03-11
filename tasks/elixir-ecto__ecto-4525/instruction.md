Schema fields declared with `field/3` using the `:writable` option are not being enforced correctly during update operations.

For example, when a schema defines a field as writable only on insert, like:

```elixir
defmodule MyApp.Accounts.Account do
  use Ecto.Schema

  schema "accounts" do
    field :firebase_uid, :string, writable: :insert
    field :deactivated_at, :utc_datetime
    timestamps(type: :utc_datetime)
  end
end
```

calling an update through `Ecto.Repo.update/2` (typically via an `Ecto.Changeset` built with `Ecto.Changeset.cast/3`) currently allows `:firebase_uid` to be changed, even though it should be treated as non-updatable.

Expected behavior: fields with `writable: :insert` must not be persisted as changes during updates. When attempting to update a struct and providing params that include such a field, the update must not write that field to the database.

Actual behavior: the update writes the new value and the returned struct reflects that persisted change.

The fix must ensure that writability is respected consistently across repo write operations:

- On insert operations, `writable: :insert` fields are allowed to be written.
- On update operations, `writable: :insert` fields are treated like read-only fields (i.e., excluded from the set of updatable fields).
- Fields marked `writable: :never` must not be written on either insert or update.

Additionally, virtual fields must continue to behave correctly: virtual field changes may appear in the returned struct after calling repo operations, but virtual fields must never be sent to the database layer. The behavior should correctly distinguish between (a) filtering changes that should not be written because they are non-writable and (b) filtering changes that should not be written because they are virtual, while still allowing virtual changes to be visible in the returned struct.