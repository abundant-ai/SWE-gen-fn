Ecto queries currently support limiting results via `limit/3`, but there is no way to express the SQL-standard `FETCH ... WITH TIES` behavior (include any extra rows that are tied with the last row in the limited set). Implement support in `Ecto.Query` for a `with_ties/2` macro that marks an existing limit as "with ties".

When building a query like:

```elixir
from(p in Post) |> limit([], 1) |> with_ties(true)
```

the query must keep `limit` set to `1` and additionally store that `with_ties` is enabled (e.g., `query.limit.with_ties == true`). It must also work when the boolean is provided at runtime via interpolation:

```elixir
"posts" |> limit([], 2) |> with_ties(^true)
```

In this case, after the query is built, `query.limit.expr` must be `2` and `query.limit.with_ties` must evaluate to `true`.

`with_ties/2` must only accept booleans, with different error behavior depending on whether the value is compile-time or runtime:

* If called with an interpolated value that does not evaluate to a boolean at runtime (example: `with_ties("posts", ^1)`), it must raise `RuntimeError` with the exact message:

```
`with_ties` expression must evaluate to a boolean at runtime, got: `1`
```

* If called with a non-interpolated, non-boolean compile-time value (example: `with_ties("posts", 1)`), it must raise `Ecto.Query.CompileError` with the exact message:

```
`with_ties` expression must be a compile time boolean or an interpolated value using ^, got: `1`
```

`with_ties/2` must only be applicable when the query already contains a `limit`. Calling it without a limit (example: `with_ties("posts", true)`) must raise `Ecto.Query.CompileError` with the exact message:

```
`with_ties` can only be applied to queries containing a `limit`
```

Finally, the `with_ties` flag must not “stick” if the user later sets a new limit. For example:

```elixir
from(p in Post) |> limit([], 1) |> with_ties(true) |> limit([], 2)
```

must result in `query.limit.expr == 2` and `query.limit.with_ties == false` (i.e., setting a new limit resets/removes the prior with-ties behavior). The same reset behavior must occur for runtime-built queries as well.

Update the query representation/planning so the new `with_ties` metadata is preserved through query building and planning without breaking existing limit/offset overriding behavior (duplicated `limit` should still override the previous one).