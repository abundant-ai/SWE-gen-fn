Full-text search filtering using the `fts` family of operators is generating SQL that fails (or behaves incorrectly) for several valid column types.

1) Regression: domain types wrapping `tsvector` break `fts` filtering.

Given a domain over `tsvector`, filtering with `fts` currently causes PostgREST to wrap the column with `to_tsvector(...)`, producing a database error because `to_tsvector` is defined for text-like inputs, not for a `tsvector` domain.

Example schema:
```sql
CREATE DOMAIN public.market_tsvector AS tsvector
  CONSTRAINT "tsvector is required" CHECK (VALUE IS NOT NULL);

CREATE TABLE public.markets (
  id UUID PRIMARY KEY,
  name TEXT,
  tsvector public.market_tsvector
);
```

Request:
```
GET /api/markets?select=id,name&tsvector=fts.asda
```

Actual error response:
```json
{
  "code": "42883",
  "details": null,
  "hint": "No function matches the given name and argument types. You might need to add explicit type casts.",
  "message": "function to_tsvector(public.market_tsvector) does not exist"
}
```

Expected behavior: applying `fts` to a column whose underlying/base type is `tsvector` should not attempt to call `to_tsvector(column)` (or otherwise require a `to_tsvector(domain_tsvector)` overload). The generated SQL should be valid and allow full-text search on the column.

2) Feature/behavior change: `fts` filters should apply `to_tsvector` to the filtered column when needed.

When using an `fts` operator (e.g., `fts`, `plfts`, `phfts`, `wfts` variants) on columns that are not already `tsvector`, the filter should be expressed in a way that explicitly converts the column to a `tsvector` before applying the `@@` operator with a `tsquery`.

For example, a request like:
```
/table?column=fts(simple).test
```
should produce a WHERE clause equivalent to:
```sql
to_tsvector('simple', column) @@ to_tsquery('simple', 'test')
```
This is required so that full-text search works for column types where implicit conversion is not available (e.g., json/jsonb) and to make the behavior consistent across types.

At the same time, for columns that are already `tsvector` (including domain-wrapped `tsvector`), the conversion must not be applied in a way that causes type resolution failures.

Overall expected behavior:
- `fts`-style operators should work on text-like columns by converting them with `to_tsvector`.
- `fts`-style operators should work on `tsvector` columns without wrapping them in `to_tsvector`.
- Domain types should be handled based on their base type for deciding whether `to_tsvector` should be applied, so `DOMAIN AS tsvector` behaves like `tsvector`.
- Requests using complex boolean logic (e.g., combined `and`/`or` filters and embedded filters) must continue to work when an `fts` filter is part of the expression, producing correct results and not raising SQL/operator/type errors.