Using an Enumerable (such as `MapSet`) as the right-hand side of an `in` expression in an Ecto query does not behave like `Kernel.in/2` and fails unexpectedly. For example:

```elixir
ids = MapSet.new([1, 2, 3])
from(c in Comment, where: c.id in ^ids)
```

This should be accepted by Ecto and treated the same as if a list had been provided (i.e., it should be cast as a list of values for the underlying element type). Currently, Ecto’s casting pipeline expects a list for array-like casting and does not automatically convert structs/values that implement the `Enumerable` protocol.

Update the casting behavior (via `Ecto.Type.cast/2` and any internal casting used for array/list parameters in queries) so that when a value is being cast to an array/list type and the value is not a list but implements the `Enumerable` protocol, Ecto converts it to a list and proceeds with casting each element.

If the value does not implement `Enumerable`, casting must fail with an appropriate error rather than silently accepting or producing a confusing failure later.

Expected behavior:
- Providing a `MapSet` (or other Enumerable struct) where a list/array is expected results in the same successful cast as providing `Enum.to_list(value)`.
- Element casting rules remain unchanged (invalid elements should still cause the cast to fail as they would for a list).
- Providing a non-list, non-enumerable value where a list/array is expected returns an error (`:error` or an equivalent error tuple consistent with existing `Ecto.Type.cast/2` conventions for that path).

Actual behavior:
- Enumerable structs like `MapSet` are rejected when used as array/list inputs (such as for `in ^value` query parameters) because they are not lists and are not coerced before casting.