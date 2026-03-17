Ecto currently has no first-class way to represent ClickHouse’s `ARRAY JOIN`. Users of the ClickHouse adapter are forced to encode this behavior using `:lateral_join`, which is semantically different and leads to confusing/incorrect query representation.

Add support for a new query expression `:array_join` that can be used in `from/2` similarly to other join-like constructs. The feature should allow writing queries like:

```elixir
from at in "arrays_test",
  array_join: a in "arr",
  select: [at.s, a]
```

When a query containing `array_join:` is inspected (via `inspect(query)`), it should include an `array_join:` clause in the textual representation in the same style as other query parts, and it should not be treated as a normal `join:`/`lateral_join:`.

The query AST should accept `array_join:` entries in `from/2`, with the same binding behavior users expect from other binding forms (i.e., the `a` binding is usable in later clauses like `select`, `where`, etc.). It must support the `a in "arr"` form at minimum.

If `array_join:` is used incorrectly (for example, with an invalid binding form), it should raise an Ecto query compile error consistent with how invalid `join:` or other query keywords are validated.

Overall expected behavior: Ecto queries can be built with `array_join:` without falling back to `:lateral_join`, the binding is available for subsequent expressions, and inspection/pretty-printing reflects the presence of the `array_join` clause rather than mislabeling it as another join type.