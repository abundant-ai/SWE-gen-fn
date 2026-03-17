When using `Ecto.Changeset.cast_assoc/3` (and similarly `cast_embed/3`) with `:sort_param`/`:drop_param` to reorder a `has_many`/`embeds_many` collection, it should be possible to compute and persist a derived “position/index” field for each child changeset without triggering Ecto’s “relation replaced twice” protection.

Currently, a common pattern is to call `cast_assoc` with sorting enabled and then iterate through the resulting child changesets to assign an index, finally writing the updated list back onto the parent with `Ecto.Changeset.put_change/3`. Example:

```elixir
changeset
|> Ecto.Changeset.cast_assoc(:addresses,
  sort_param: :addresses_sort,
  drop_param: :addresses_drop
)
|> copy_children_positions()

defp copy_children_positions(changeset) do
  if children = Ecto.Changeset.get_change(changeset, :children) do
    children
    |> Enum.with_index(fn child, index ->
      Ecto.Changeset.put_change(child, :position, index)
    end)
    |> then(&Ecto.Changeset.put_change(changeset, :children, &1))
  else
    changeset
  end
end
```

With current behavior, updating the parent association/embed change in this way fails with a runtime error:

```
** (RuntimeError) cannot replace related %Address{...}
This typically happens when you are calling put_assoc/put_embed with the results of a previous
put_assoc/put_embed/cast_assoc/cast_embed operation, which is not supported. You must call
such operations only once per embed/assoc, in order for Ecto to track changes efficiently
```

This should work when the new value being put back is the same relation result produced by `cast_assoc`/`cast_embed`, just with additional per-child changes (such as setting `:position` based on final order).

Fix the relation casting/put_change behavior so that after `cast_assoc/3` or `cast_embed/3` has applied sorting/dropping, the resulting child changesets can be updated (including based on their sorted index) and the updated list can be stored back on the parent changeset without raising `cannot replace related ...`. The final persisted/produced changeset should reflect the correct reordered list and the computed index/position values for each child in that order.

The change must apply consistently to both associations (`has_many`) and embeds (`embeds_many`), including when a child changeset function expects an index/position to be provided/available from the casting operation.