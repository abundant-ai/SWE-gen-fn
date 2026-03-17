Ecto’s query DSL currently provides `Ecto.Query.order_by/3` (and related behavior via `order_by:` in `from/2`) for adding ordering to a query, but there is no supported way to *prepend* new order-by expressions ahead of any existing order-bys while still honoring the existing `:mode` behavior. As a result, callers who need to ensure a higher-priority ordering (for example, always order by a stable primary key first, then apply user-supplied ordering) can only append additional order-bys, which changes the resulting ordering precedence.

Implement a new public API `Ecto.Query.prepend_order_by/3` that mirrors `Ecto.Query.order_by/3` but inserts the given order-by expression(s) at the beginning of the query’s existing order_bys list.

The new function must accept the same shapes as `order_by/3`, including:

- A single expression (defaulting to ascending), such as `prepend_order_by(query, [p], p.inserted_at)` or `prepend_order_by(query, [p], :inserted_at)`.
- A list of fields/expressions, such as `prepend_order_by(query, [p], [p.title, p.id])`.
- A keyword list with explicit directions, such as `prepend_order_by(query, [p], [asc: p.title, desc: p.id])`.
- Support for the extended directions `:asc_nulls_first`, `:asc_nulls_last`, `:desc_nulls_first`, and `:desc_nulls_last`.
- Support for ordering by `selected_as/1` references (for example `selected_as(:ident)`), both with default direction and explicit direction.

It must also correctly interact with the existing `:mode` option for order-by construction. In particular, whatever behavior currently exists for `order_by/3` regarding `:mode` (for example, modes that control whether new order_bys replace, append to, or otherwise combine with existing order_bys) must remain correct, and `prepend_order_by/3` must apply the mode semantics consistently while ensuring that when “prepend” behavior is intended, the new expressions end up ahead of existing ones.

Error handling must match existing order-by compilation behavior:

- Referencing an unbound variable in the order-by expression must raise `Ecto.Query.CompileError` with a message indicating an unbound variable in the query.
- Using an unknown order-by direction (anything other than the supported directions or an interpolated value) must raise `Ecto.Query.CompileError` indicating the expected directions and showing the invalid one.

Example of expected ordering precedence:

```elixir
q = from(p in "posts", order_by: [desc: p.inserted_at])
q = Ecto.Query.prepend_order_by(q, [p], [asc: p.id])

# The resulting query should order by p.id first, then p.inserted_at
```

After implementing this, `prepend_order_by/3` should behave consistently with the existing `order_by` DSL for expression escaping, supported directions, and compilation errors, while guaranteeing that prepended order-bys appear before existing ones in the final query.