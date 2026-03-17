Ecto query sources should support using an in-memory “values list” as a data source in both `from` and `join` expressions.

Currently, using `values(values, types)` as a query source is not supported (or is not validated/compiled correctly), so queries like the following cannot be represented correctly in the query AST and/or raise unexpected errors:

```elixir
import Ecto.Query

values = [%{num: 1, text: "one"}, %{num: 2, text: "two"}]
types  = %{num: :integer, text: :string}

q1 = from v in values(values, types)
q2 = from p in "posts", join: v in values(values, types), on: true
```

When `values/2` is used as a source, the query should store a `:values` source tuple that includes (1) the declared types as a keyword list and (2) the number of rows. For the example above, the source must be represented as:

```elixir
{:values, [], [[num: :integer, text: :string], 2]}
```

This must work in both `from` (i.e., `query.from.source`) and `join` (i.e., `join.source`).

The `values/2` source must also validate inputs and raise `ArgumentError` with the following exact messages:

1) If `types` does not declare a type for every field present in the values rows, raise:

"values/2 must declare the type for every field. The type was not given for field `FIELD`"

For example, if the rows include `:text` but `types` only includes `:num`, it must raise:

"values/2 must declare the type for every field. The type was not given for field `text`"

2) If not all rows in the values list have the same fields, raise:

"each member of a values list must have the same fields. Missing field `FIELD` in ROW"

For example, if one row is `%{num: 2}` while others include `:text`, it must raise:

"each member of a values list must have the same fields. Missing field `text` in %{num: 2}"

Additionally, query inspection must be able to handle queries that include `:values` sources without crashing or producing malformed output (i.e., inspecting a query containing a values-list source should work consistently alongside other source types).