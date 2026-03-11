Using a macro that returns an `order_by` expression (especially a keyword list of multiple order clauses) currently fails to compile when used inside `from/2` or `Ecto.Query.order_by/3`.

For example, defining a macro that returns a list of orderings:

```elixir
defmacro my_custom_order(t) do
  quote do
    [desc: unquote(t).id, asc: unquote(t).inserted_at]
  end
end
```

and then using it in a query:

```elixir
from p in Post, order_by: my_custom_order(p)
```

raises:

```
** (Ecto.Query.CompileError) Tuples can only be used in comparisons with literal tuples of the same size
    (ecto ...) expanding macro: Ecto.Query.order_by/3
```

The `order_by` builder should correctly expand macros passed as the `order_by` expression and then treat the expanded AST as an `order_by` expression, including support for:

- A keyword list of multiple order terms, e.g. `[desc: p.id, asc: p.inserted_at]`
- Mixed complex expressions inside the order list, such as `fragment/1` expressions (e.g. `fragment("lower(?)", p.title)`), window function expressions like `nth_value(p.links, 1)`, and combinations of multiple terms in a single macro
- Correct parameter handling when the expanded expression includes parameters

After the fix, macro-based `order_by` expressions like `my_custom_order(p)` should compile without errors and produce the same ordering AST as if the equivalent list/expression were written inline.