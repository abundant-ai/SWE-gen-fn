Ecto’s internal representation for common table expressions (CTEs) stored in a query’s `with_ctes` is currently too brittle for adapter authors. It was changed to a tuple shape like `{name, materialized, query}`, which is a breaking change for adapters that consume `query.with_ctes.queries`.

Update Ecto so that each CTE entry in `query.with_ctes.queries` is represented as `{name, opts, query}`, where:

- `name` is the CTE name as a string.
- `opts` is a map of CTE options (at minimum it must support `:materialized` when provided; if no options are given, it must be an empty map `%{}` rather than `nil`).
- `query` is the CTE query expression (either an `%Ecto.Query{}` or an `%Ecto.Query.QueryExpr{}` when using a fragment CTE).

The public query-building API must continue to work as before:

- `Ecto.Query.with_cte/3` must accept `as: ...` with either a query (pinned with `^`) or a fragment expression.
- `with_cte/3` must accept `materialized: true` and `materialized: false` and store it in the `opts` map as `%{materialized: true}` or `%{materialized: false}`.
- If `materialized` is not provided, `opts` must be `%{}`.
- `Ecto.Query.recursive_ctes/2` must continue to control `query.with_ctes.recursive`, and must be overridable by subsequent calls (setting it to `true` then `false` must result in `false`).

CTE composition behavior must remain correct:

- Adding multiple CTEs via multiple `with_cte/3` calls must append/merge into `query.with_ctes.queries` while preserving each entry’s `{name, opts, query}` shape.
- Recursive CTE queries (built via `union_all/2` and used as `as: ^tree`) must round-trip such that the stored CTE query is the same query structure that was provided.

Compile-time validation must remain intact:

- Passing `as: %Ecto.Query{}` without `^` must raise `Ecto.Query.CompileError` indicating it is not a valid CTE.
- Passing an invalid CTE definition (for example a raw string instead of a fragment) must raise `Ecto.Query.CompileError` indicating it is not a valid CTE.

Finally, ensure query planning continues to work with the new CTE tuple shape (planners/adapters must be able to read `query.with_ctes.queries` without depending on a fixed positional materialized field).