Using `selected_as/2` inside a query that will later be wrapped in `subquery/1` currently raises a runtime error during planning/compilation, even when the alias is only referenced within the inner query itself.

Reproduction example:

```elixir
import Ecto.Query

def foo_query do
  from(m in Model,
    select: %{bar: selected_as(fragment("complex(?)", m.column), :foo)},
    group_by: [selected_as(:foo)]
  )
end

query =
  from(o in subquery(other_query()),
    join: s in subquery(foo_query()),
    on: o.bar == s.bar
  )
```

Actual behavior: planning the outer query fails with an error like:

```
`selected_as/2` can only be used in the outer most `select` expression. If you are attempting to alias a field from a subquery or cte, it is not allowed because the fields are automatically aliased by the corresponding map/struct key. The following field aliases were specified: [:foo].
```

This is misleading in cases where `selected_as(:foo)` is not being used from the outer query to reference subquery fields; it is only being used within the inner query to refer to an aliased select expression (e.g., in `group_by`, `order_by`, `having`, etc.). The alias should be scoped to the query where it is defined and should not “leak” as an invalid alias usage when that query is wrapped by `subquery/1`.

Expected behavior: `selected_as/2` should be allowed when used entirely within the same query that defines the alias, even if that query is later used as a subquery (or nested further). Wrapping such a query in `subquery/1` should not cause a `selected_as/2` scoping error as long as the outer query is not attempting to reference the subquery’s internal `selected_as` alias directly.

Additionally, when an inner query uses `selected_as` to name a selected field (e.g., `selected_as(expr, :foo)` in the select), the outer query should be able to refer to that projected field using the normal projected field name (the map/keyword key), without needing to know or use the internal `selected_as` alias name. In other words, selecting `%{bar: selected_as(..., :foo)}` should expose the field to the outer query as `bar`, and should not force/encourage referencing `:foo` from outside the subquery.