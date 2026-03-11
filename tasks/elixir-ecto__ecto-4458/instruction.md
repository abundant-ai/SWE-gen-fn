There is a regression in Ecto’s `order_by` query compilation when the `order_by` expression is produced by a macro that returns a list of expressions. Macros like:

```elixir
defmacro my_custom_order(p) do
  quote do
    [unquote(p).id, some_sql_function(unquote(p))]
  end
end
```

should be valid to use in `order_by`, but currently fail because the `order_by` expression gets escaped twice: once when the macro expands and again when recursion walks the resulting AST. This double-escaping breaks cases where the macro expands into a list containing multiple order-by expressions (including a mix of plain fields, fragments, and window functions).

When calling `Ecto.Query.Builder.OrderBy.escape/6` with an `order_by` expression that is a macro call returning a list, the result should be a single escaped `order_by` AST where each element is escaped exactly once.

For example, calling `escape(:order_by, quote(do: my_custom_order(x)), {[], %{}}, [x: 0], __ENV__)` should return an escaped AST equivalent to an `order_by` list like:

- `&0.id()`
- `fragment("lower(?)", &0.title())` (or an equivalent fragment AST if the macro builds a fragment)
- `nth_value(&0.links(), 1)`

and it must not raise compile errors or produce malformed AST due to double escaping.

Additionally, more complex macros that return keyword lists with directions (e.g. `desc: p.id, asc: ...`) should also compile correctly and preserve the specified directions (`:asc`, `:desc`, and `:_nulls_first`/`:_nulls_last` variants).

The fix should ensure `Ecto.Query.Builder.OrderBy.escape/6` expands/escapes the `order_by` expression at the correct stage (before descending into recursive handling of list/keyword forms), so that macro-produced lists and keyword lists are handled correctly without any element being escaped twice.