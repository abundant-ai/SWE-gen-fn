PostgREST currently supports a set of filter operators in query parameters (e.g., `eq`, `gt`, `is.null`, etc.), but it does not support PostgreSQL’s comparison predicate `IS DISTINCT FROM`. This prevents clients from expressing “not equal, but NULL-safe” comparisons through the HTTP API.

Implement support for filtering with `IS DISTINCT FROM` (and its negated form) in the same style as existing filter operators.

When a client requests a resource with a filter like:

- `GET /items?col=isdistinct.value`

PostgREST should generate SQL equivalent to:

- `WHERE col IS DISTINCT FROM value`

It must also work with the existing `not` modifier so that:

- `GET /items?col=not.isdistinct.value`

is equivalent to:

- `WHERE NOT (col IS DISTINCT FROM value)`

The operator must be usable anywhere other filter operators are accepted, including inside complex boolean logic expressed through `and`/`or` parameters and at embedded levels (e.g., within nested expressions and embedded resource filters).

Behavior requirements:
- The new operator token should be recognized and parsed as a filter operator.
- SQL rendering must use `IS DISTINCT FROM` (not `<>`) so that comparisons are NULL-safe.
- The operator must accept the same kinds of right-hand values as other binary comparison operators (literals and appropriately typed values), and participate in existing negation semantics via `not.`.
- If an unknown operator name is provided, behavior should remain unchanged (i.e., it should still be rejected as before); only `isdistinct` (or the chosen canonical name for this operator) should be added.

Additions should integrate with existing query filtering so that `isdistinct` behaves consistently with other operators in terms of precedence, nesting, and error handling.