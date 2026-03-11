`Ecto.Query.literal/1` currently only accepts identifier-like values (used primarily inside `fragment/1`) and rejects numbers. This prevents writing queries for databases that do not allow bound query parameters in `LIMIT` expressions while still needing dynamic limit values.

When building a query that uses `literal/1` with a numeric value (including interpolated values), query compilation fails instead of producing a query AST that treats the number as a literal value.

Update `Ecto.Query.literal/1` so it accepts numbers (integers and floats) in addition to its existing supported identifier forms. After the change, calls like the following should compile successfully and treat the numeric argument as a literal value in the generated query expression:

```elixir
limit_value = 10
from(p in "posts", limit: fragment("?", literal(^limit_value)))
```

`literal/1` should continue to reject unsupported types (for example, values where it would be ambiguous or unsafe to interpret them as literals), and existing behavior for identifier literals must remain unchanged.

Expected behavior: using `literal/1` with numeric values should compile and build a valid query expression.
Actual behavior: using `literal/1` with numeric values raises an Ecto query compile-time error complaining that the argument is not a valid literal.