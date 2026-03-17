When building Ecto queries that include joins, Ecto currently allows a join to omit the `:on` option in cases where the join is not an association join (i.e., it is not `assoc/2`). In those cases, the join condition implicitly defaults to `true`, which can silently produce accidental cartesian products.

Ecto should emit a warning whenever a join is created without an explicit `:on` clause and the join is not an association join. This warning should apply to joins created via `join/5` as well as join keywords in `from/2`.

For example, constructing a query like:

```elixir
import Ecto.Query

q =
  from p in "posts",
    join: c in "comments"
```

currently builds a join with `on: true` without any notice. Instead, building such a query should still succeed, but it must warn that `:on` is missing and that the join condition defaulted to `true`.

The warning must NOT be emitted for association joins where the `on` condition is derived implicitly from the association, such as:

```elixir
from p in Post,
  join: c in assoc(p, :comments)
```

Additionally, joins that already provide an `:on` expression must not warn, e.g.:

```elixir
from p in "posts",
  join: c in "comments",
  on: c.post_id == p.id
```

The warning should be emitted consistently regardless of whether the join source is a schema, a string source, a fragment-like source, or a subquery used as a join source. It should also avoid duplicate warnings for the same join when a query goes through planning/normalization/inspection multiple times.

Expected behavior: missing-`:on` non-association joins warn and still default to `on: true`.
Actual behavior: missing-`:on` non-association joins default to `on: true` silently.