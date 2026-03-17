When updating a schema through `Repo.update/2`, `belongs_to` associations can become inconsistent if the foreign key field is changed via the changeset while the association field was previously preloaded on the struct.

Reproduction example:

```elixir
revenue = Repo.get!(Revenue, id) |> Repo.preload(:wallet)
{:ok, updated} =
  revenue
  |> Ecto.Changeset.cast(%{wallet_id: new_wallet_id}, [:wallet_id])
  |> Repo.update()

# updated.wallet_id == new_wallet_id
# but updated.wallet still points to the previously preloaded wallet
```

Current behavior: after a successful `Repo.update/2`, the returned struct may contain a preloaded `belongs_to` association whose `id` no longer matches the updated foreign key (e.g., `updated.wallet.id != updated.wallet_id`). This can silently lead to incorrect application behavior because the struct appears to have a loaded association but it is stale.

Expected behavior: if an update changes a `belongs_to` foreign key (for example `:wallet_id`) and the corresponding association field (for example `:wallet`) was not explicitly changed via association APIs, then the association field in the returned struct must be reset to `Ecto.Association.NotLoaded` (or otherwise made consistent) so that `updated.wallet` is not a stale, mismatched struct.

This should only apply to updates where:
- the foreign key field is changed in the changeset, and
- the association field itself is not part of the changeset changes.

If both the foreign key and the association are changed in the same changeset, Ecto should continue to raise on mismatches or otherwise enforce consistency as it already does.

The fix should ensure that after `Repo.update/2` returns `{:ok, struct}`, no `belongs_to` association remains loaded with an `id` that conflicts with the corresponding foreign key value on the parent struct.