Ecto currently rejects subqueries used inside certain query clauses, raising an ArgumentError even when the subquery expression is valid elsewhere in the query. In particular, using an expression like `exists(subquery)` inside `order_by` fails during dynamic expansion with:

```
** (ArgumentError) subqueries are not allowed in `order_by` expressions
```

This breaks use cases where a calculated boolean (implemented as an `exists(...)` subquery) is used for sorting, and similar patterns should be supported consistently across other clauses.

The query builder should accept and correctly represent subqueries inside these clauses:

- `order_by`
- `group_by`
- `distinct`
- window definitions used via `windows`

For example, the following patterns should compile and produce a query expression that contains a placeholder reference to a collected subquery (and the query should retain the collected subquery metadata alongside the expression):

```elixir
from p in "posts",
  as: :p,
  order_by: [
    desc: dynamic([p], exists(from other_post in "posts",
                              where: other_post.id == parent_as(:p).id))
  ]
```

```elixir
from p in "posts",
  as: :p,
  group_by: dynamic([p], exists(from other_q in "q",
                               where: other_q.title == parent_as(:q).title))
```

```elixir
from p in "posts",
  as: :p,
  distinct: [
    asc: dynamic([p], exists(from other_post in "posts",
                             where: other_post.id == parent_as(:p).id))
  ]
```

The expected behavior is that these clauses no longer raise due to “subqueries are not allowed …”, and instead produce a valid `Ecto.Query` where the clause expression includes an `{:exists, ..., [subquery: index]}` (or equivalent) marker and the corresponding subquery is stored in the expression’s `subqueries` collection.

This support should work both when the clause is built from:

- `dynamic/2` expressions
- direct clause expressions using `exists(from ... )`
- interpolated (`^value`) runtime forms passed into `order_by`, `group_by`, and `distinct`

At the same time, existing validations should remain intact (for example, unknown ordering directions in `order_by` should still raise `Ecto.Query.CompileError`, and invalid field inputs should still raise the current ArgumentError/compile errors).