Calling `Repo.insert_all/3` with a query source that uses `select_merge` with literal maps can incorrectly raise an `ArgumentError` claiming the query selected both `map/2` and a literal map.

Reproduction example:

```elixir
new_comment_notifications =
  from cn in ImageCommentNotification,
    where: cn.image_id == ^source.id,
    select_merge: %{
      user_id: cn.user_id,
      image_id: ^target.id,
      comment_id: cn.comment_id
    },
    select_merge: %{
      read: cn.read,
      inserted_at: cn.inserted_at,
      updated_at: cn.updated_at
    }

Repo.insert_all(ImageCommentNotification, new_comment_notifications, on_conflict: :nothing)
```

Actual behavior: it raises

```
** (ArgumentError) the source query given to `insert_all` has selected both `map/2` and
a literal map: ...

when using `select_merge` with `insert_all`, you must always use literal
maps or always use `map/2`. The two cannot be combined.
```

This is misleading in cases where the query uses only literal maps (as above) and does not explicitly use `map/2`.

Expected behavior: `Repo.insert_all/3` should not raise this “mixed `map/2` and literal map” error for queries built exclusively from literal maps via `select_merge`. If the query is actually unsupported for a different reason, `insert_all` should raise an error that accurately explains the real incompatibility (i.e., the message should not claim `map/2` was selected when it wasn’t).

The fix should ensure that the validation/inspection of the query’s select expression used by `insert_all` properly distinguishes between (a) literal map merges and (b) `map/2`-based selections, including when multiple `select_merge` calls are chained and the final select expression is nested as merges. Any raised `ArgumentError` must reflect the true structure of the select expression.