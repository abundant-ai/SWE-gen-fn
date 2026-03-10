PostgREST currently supports filters like `eq`, `like`, `ilike`, `gt`, `gte`, `lt`, `lte`, `match`, and `imatch`, but it does not allow applying PostgreSQL’s `ANY`/`ALL` array modifiers to these operators. This prevents clients from expressing compact “match any of these values/patterns” or “match all of these values/patterns” conditions without expanding them into long `or=(...)` expressions.

Add support for `any` and `all` modifiers in the filter syntax for the operators `eq, like, ilike, gt, gte, lt, lte, match, imatch`, using a syntax of the form:

- `GET /projects?id=eq(any).{3,4,5}` which must translate to SQL semantics equivalent to `id = ANY('{3,4,5}')`
- `GET /articles?body=ilike(all).{%plan%,%greatness%}` which must translate to SQL semantics equivalent to `body ILIKE ALL('{%plan%,%greatness%}')` (and likewise for `LIKE`, `=`, comparisons, and match operators)

The modifier is part of the operator token, i.e. `eq(any)` or `ilike(all)`, and the right-hand side is an array literal expressed with curly braces `{...}` (including strings/patterns like `%plan%`). The generated SQL must apply `ANY`/`ALL` to the array of provided values rather than expanding into multiple OR/AND expressions.

This feature must be limited to the listed operators only. Do not attempt to support `ANY/ALL` for operators that do not work correctly with array modifiers in PostgreSQL (for example containment operators like `cs/cd`, range operators like `ov/sl/sr/nxl/nxr/adj`, or full-text search operators), because PostgreSQL cannot type-resolve expressions like `'{3,4}'::int[] @> ANY('{3,4,5}')`.

Expected behavior examples:

- Filtering with `eq(any)` returns rows where the column equals at least one element in the provided array.
- Filtering with `like(all)` / `ilike(all)` returns rows where the column matches every pattern in the array.
- Comparison operators with modifiers (e.g. `gt(any)` / `lte(all)`) should behave as PostgreSQL defines for `> ANY(array)` and `<= ALL(array)`.

If a client attempts to use `any/all` modifiers with unsupported operators, PostgREST should reject the request with a clear, consistent error rather than producing invalid SQL.