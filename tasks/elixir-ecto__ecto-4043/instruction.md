Using `selected_as/2` inside a Common Table Expression (CTE) currently fails during query planning, even though the same `selected_as` usage works in non-CTE queries. When a query defines a CTE whose `select` (or inner subquery select) uses `selected_as`, planning the query raises an error instead of accepting the alias and allowing it to be referenced.

This should be supported: developers should be able to create a CTE where selected fields are aliased via `selected_as`, and then reference those aliases from the outer query (for example in `select`, `where`, `order_by`, etc.) without planner errors.

Additionally, the error message shown when `selected_as` is used incorrectly inside a subquery contains a typo and should be corrected so the message is accurate and properly spelled.

Reproduction example (illustrative):

```elixir
import Ecto.Query

cte_query =
  from p in "posts",
    select: %{id: p.id, visits: selected_as(p.visits, :visits)}

q =
  "posts"
  |> with_cte("p", as: ^cte_query)
  |> join(:inner, [x], p in "p", on: true)
  |> select([_x, p], selected_as(p.visits, :visits))
```

Expected behavior: the query can be planned/executed successfully, and the `selected_as` alias inside the CTE is recognized/propagated so it can be referenced from the outer query.

Actual behavior: planning the query raises due to `selected_as` being rejected or not handled when it appears inside a CTE.

Fix the planner/validation so `selected_as` is allowed within CTE definitions and behaves consistently with non-CTE queries, and correct the typo in the subquery `selected_as` error message.