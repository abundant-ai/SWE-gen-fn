Full-text search filtering regressed in PostgREST v13 for columns whose SQL type is a DOMAIN over `tsvector`. When a table has a column defined as a domain wrapping `tsvector`, applying the `fts` filter operator causes PostgREST to generate SQL that incorrectly tries to call `to_tsvector()` on the domain type, which fails because PostgreSQL does not have `to_tsvector(domain_over_tsvector)`.

Reproduction example:

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

Current behavior returns a PostgreSQL error like:

```json
{
  "code": "42883",
  "details": null,
  "hint": "No function matches the given name and argument types. You might need to add explicit type casts.",
  "message": "function to_tsvector(public.market_tsvector) does not exist"
}
```

Expected behavior: PostgREST should recognize that `public.market_tsvector` is a domain whose base type is `tsvector`, and it should build the FTS predicate using the underlying `tsvector` semantics without wrapping the column in `to_tsvector()` (or otherwise requiring a `to_tsvector(domain_type)` overload). The `fts` operator should work the same way as it did in PostgREST v12 and earlier for domain-wrapped `tsvector` columns.

The fix should ensure that wherever PostgREST decides how to apply full-text search operators (and more generally when checking operator/function compatibility for filters), domain types are unwrapped to their base types for resolution purposes. This should restore support for semantic domain types over `tsvector` while keeping domain constraints intact.