Ecto queries currently require the number of placeholders in `fragment/2+` to match the number of provided arguments at compile time, which makes it awkward (or impossible) to build fragments that take a variable number of parameters while still producing a stable query shape. This limitation forces users into patterns like generating different fragment strings depending on list length, which prevents efficient query caching in cases like dynamic `IN` lists or variadic database functions.

Add support for a new `splice/1` construct that can be used inside `fragment(...)` arguments to expand a runtime list into multiple fragment parameters.

For example, users should be able to write:

```elixir
import Ecto.Query

a = 2
b = 3

query =
  from p in "posts",
    where: p.id in fragment("(?, ?, ?)", 1, splice(^[a, b, 4]), 5)

# The fragment should behave as if it were written with all values expanded
# fragment("(?, ?, ?, ?, ?)", 1, 2, 3, 4, 5)
```

Expected behavior:
- `splice(^list)` inside `fragment` expands the list elements in-place as if each element had been passed as its own fragment argument.
- The produced query expression should reflect the expanded placeholders and parameters in the correct order.
- Splicing must work when the spliced value is a runtime interpolated value (`^list`), and it should integrate with normal query parameterization (i.e., it must not inline raw SQL; it should still be treated as query parameters).
- Splicing should be allowed alongside regular fragment arguments, before and after the spliced segment.

Error/edge-case behavior:
- Using `splice/1` with a non-list value should raise an `ArgumentError` (or an `Ecto.Query.CompileError` when detectable at compile time) explaining that `splice` expects a list.
- Using an empty list should produce a valid expanded fragment (no inserted arguments) and must not corrupt placeholder numbering/order.
- If the fragment string has placeholders that no longer match the effective expanded argument count after splicing, Ecto should raise a clear query compile error indicating the mismatch.

This feature is needed to support database patterns where a stable query shape is required (to allow caching) but the number of values is variable, including dynamic `IN` lists and calling variadic SQL functions via `fragment`.