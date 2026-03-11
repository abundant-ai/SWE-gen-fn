`Ecto.Repo.insert_all/3` does not currently accept literal Ecto schema structs as entries to insert, even though it accepts maps/keywords and can accept a schema module as the first argument. When a user passes a struct instance (for example `%MySchema{...}`) as one of the rows, `insert_all/3` should treat it as insert data the same way it treats map/keyword entries: use the schema’s metadata to determine the appropriate source fields and dump values, and ignore non-persisted fields.

For example, inserting a list of structs should work:

```elixir
structs = [
  %MySchema{x: "a", y: <<1>>, w: "virtual"},
  %MySchema{x: "b", y: <<2>>}
]

Repo.insert_all(MySchema, structs)
```

Expected behavior: the call succeeds and inserts rows using only schema-backed fields (respecting field sources like `source: :yyy`, defaults, and excluding virtual fields). It should behave consistently with inserting the equivalent list of maps/keywords for the same schema.

Actual behavior: passing a literal struct as an entry causes `insert_all/3` to reject the entry type and fail instead of inserting.

This support should integrate with existing `insert_all/3` semantics for schemas, including:
- handling `@schema_prefix` / prefixes when a schema has one
- using schema field definitions for dumping values to database types
- ignoring associations and embeds as insertable values unless they are represented via their foreign key fields (e.g., `parent_id`), consistent with current `insert_all` rules

Implement struct acceptance so that a struct entry is handled as input data rather than an invalid type, and ensure behavior matches map/keyword inputs for the same data.