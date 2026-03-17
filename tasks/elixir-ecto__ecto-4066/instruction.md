Ecto queries support common table expressions (CTEs) via `with_cte/3`, but there is currently no way to control PostgreSQL’s CTE materialization behavior. PostgreSQL 12+ no longer materializes CTEs by default, and users sometimes need an optimization fence by emitting `MATERIALIZED`, or explicitly requesting `NOT MATERIALIZED`.

Extend CTE support so `with_cte/3` accepts a `:materialized` option and preserves it in the query’s internal CTE representation.

When building a query like:

```elixir
cte = from c in "categories", where: not is_nil(c.parent_id)
q = from(p in "products")
    |> with_cte("categories", as: ^cte, materialized: true)
```

the CTE entry stored on the query must include the materialization flag, so that the CTE is represented as `{name, true, cte_query}` (with `true` meaning materialized).

Similarly, `materialized: false` must be supported and stored as `{name, false, cte_query}`.

If `:materialized` is not provided, existing behavior must remain unchanged and the stored value must be `nil` (e.g. `{name, nil, cte_query}`), so existing code that doesn’t opt in continues to work.

The feature must work for CTEs defined from both fragments and interpolated queries (`as: fragment("...")` and `as: ^query`). It must also continue to work with recursive CTEs (`recursive_ctes/2`) and with multiple CTEs chained together.

Finally, the query inspection output must remain valid and should reflect CTE definitions in a way that does not break existing `inspect/1` formatting for queries using CTEs. Any internal planning/normalization that processes `with_ctes` must accept the new `{name, materialized_flag, expr}` tuple form and must not raise or mis-handle queries when `materialized_flag` is `true` or `false`.

Expected behavior summary:
- `with_cte(name, as: ^cte, materialized: true)` stores `true` for that CTE’s materialization flag.
- `with_cte(name, as: ^cte, materialized: false)` stores `false`.
- `with_cte(name, as: ^cte)` stores `nil` (backwards compatible).
- Recursive CTE behavior (`recursive_ctes/2`) is unchanged and independent of `:materialized`.
- Existing compile-time validation remains: passing a query without `^` (or passing a raw string without `fragment/1`) must still raise `Ecto.Query.CompileError` indicating it is not a valid CTE.