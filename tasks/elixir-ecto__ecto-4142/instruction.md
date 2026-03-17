Ecto’s `cast_embed/3` and `cast_assoc/3` should support receiving "many" embed/association params not only as a list, but also as a map keyed by integer indexes (or strings representing integers). This is particularly important when using the `:sort_param` and `:drop_param` options, which are meant to reorder or remove entries from the incoming params before casting.

Currently, when `cast_embed/3` (and similarly `cast_assoc/3`) is given params like:

```elixir
%{
  "name" => "john doe",
  "addresses" => %{
    0 => %{"street" => "somewhere", "country" => "brazil", "id" => 1},
    1 => %{"street" => "elsewhere", "country" => "poland"}
  },
  "addresses_drop" => [0]
}
```

and the embed/assoc is cast with:

```elixir
cast_embed(changeset, :addresses, drop_param: :addresses_drop)
```

the entry at index `0` should be removed from the data before the embed is cast. This behavior should work regardless of whether the underlying `"addresses"` data is provided as a list or as an index-keyed map. (This also assumes the embed/association was defined with an appropriate `:on_replace` option such as `:delete`.)

Similarly, `:sort_param` should work with index-keyed maps. Given params like:

```elixir
%{
  "name" => "john doe",
  "addresses" => %{0 => %{...}, 1 => %{...}},
  "addresses_sort" => [1, 0]
}
```

and casting with:

```elixir
cast_embed(changeset, :addresses, sort_param: :addresses_sort)
```

the elements must be reordered so that index `1` comes before index `0` for casting.

Sorting rules that must be implemented:

- Any index not present in the `"addresses_sort"` list must come *before* any of the explicitly sorted indexes.
- If an index listed in `"addresses_sort"` is not found in the incoming data, an empty entry must be inserted in that position so casting still produces a corresponding embedded/associated changeset (which may then be invalid depending on validations).

Dropping rules that must be implemented:

- Entries whose indexes appear in the `drop_param` list must be removed prior to casting.
- This must work for list-form input and for index-keyed map input.

The end result is that `cast_embed/3` and `cast_assoc/3` behave consistently for many embeds/associations whether the incoming params represent collections as lists or as maps keyed by positional indexes, and `:sort_param`/`:drop_param` correctly reorder/remove items before casting.