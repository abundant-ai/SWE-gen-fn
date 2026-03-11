Calling `Ecto.Query.API.values/2` with an empty list currently produces invalid SQL when used as a query source (for example in `from` or joins). For instance, building a query like:

```elixir
(from r in "users",
 join: v in values([], %{id: :binary_id}),
 as: :values,
 on: r.id == v.id)
|> Repo.exists?()
```

can generate SQL similar to:

```sql
SELECT TRUE FROM "users" AS u0 INNER JOIN (VALUES (),()) AS v1 () ON u0."id" = v1."id" LIMIT 1
```

and then fails at the database level with an error like:

```
** (Postgrex.Error) ERROR 42601 (syntax_error) syntax error at or near ")"
```

This should not reach the database adapter with malformed SQL. When `values/2` is given an empty list, Ecto should fail early while building the query and raise `ArgumentError` with the message:

```
must provide a non-empty list to values/2
```

The early validation should happen when constructing the query expression that uses `values/2` (e.g., `from v in values([], %{})` should raise immediately), rather than deferring to SQL generation/execution.