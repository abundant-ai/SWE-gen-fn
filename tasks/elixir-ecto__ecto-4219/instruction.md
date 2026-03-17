`many_to_many` associations cannot currently be consistently ordered by columns that live on the join table when preloading or when using `Ecto.assoc/2`. This is a problem for relationships where the join table stores metadata (for example, a position/rank, inserted_at, or other attributes) and consumers expect the preloaded collection to come back in a deterministic order.

When defining a `many_to_many` association in a schema, developers need a way to specify an ordering that targets the join table (not just the related schema’s table). After defining such an option, calling `Repo.preload(parent, :assoc)` (and also building queries via `Ecto.assoc(parent, :assoc)`) should return the associated records ordered according to the join table ordering.

Currently, any attempt to express join-table-based ordering either cannot be represented in the association definition, is ignored during preload, or is not applied consistently between `Repo.preload/2` and `Ecto.assoc/2`. The result is that associated entries come back in an unspecified order, even though the join table contains the intended ordering column.

Implement support for ordering `many_to_many` preloads by join table columns via a schema-level option on the association (in addition to any existing preload ordering for the related table). The ordering must be compiled into the queries Ecto generates for:

- Preloading the `many_to_many` association (including nested preloads)
- `Ecto.assoc(parent, :many_to_many_assoc)` queries

The option should accept the same kinds of order expressions users can write in Ecto (for example, lists like `[asc: :field]`, `[desc: :field]`, and variants such as `:asc_nulls_first` / `:desc_nulls_last`), but interpreted against the join table’s fields/sources. Ordering should be stable and deterministic when the join-table ordering is given.

If an invalid ordering direction or invalid expression is provided, it should raise an `Ecto.Query.CompileError` with the same style of messaging as other invalid `order_by` expressions.

Example of the desired behavior (names illustrative):

```elixir
schema "posts" do
  many_to_many :tags, Tag,
    join_through: "posts_tags",
    join_keys: [post_id: :id, tag_id: :id],
    preload_order: [asc: :name],
    join_preload_order: [asc: :position]
end

post = Repo.get!(Post, 1) |> Repo.preload(:tags)
# Expected: post.tags ordered by posts_tags.position (and then any additional ordering as defined)
```

After the change, ordering specified for the join table must actually affect the SQL/query ordering Ecto generates for loading the association, rather than being ignored or applied to the wrong binding/source.