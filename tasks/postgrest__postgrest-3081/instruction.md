Querying JSON/JSONB fields via PostgREST fails when a JSON object key contains special characters such as `@`, even though these keys are valid in PostgreSQL JSON operators. For example, a request like:

```bash
curl 'http://localhost:3000/bets?data_json->@type=eq.4'
```

currently returns an error similar to:

```json
{
  "code":"PGRST100",
  "details":"unexpected \"@\" expecting \"-\", digit or field name (* or [a..z0..9_$])",
  "hint":null,
  "message":"\"failed to parse tree path (data_json->@type)\" (line 1, column 12)"
}
```

This happens because the JSON path/key parser is overly restrictive and treats JSON keys like SQL identifiers, rejecting characters that are valid JSON keys (e.g. `@` in `@type`, commonly used by schema.org/schema-dts).

Update PostgREST’s parsing of JSON/JSONB operators in both `select` shaping expressions and filter/tree paths so that JSON keys may include non-reserved special characters such as `@` (and other similar symbols) without requiring quoting/escaping beyond normal URL encoding rules. After the fix, requests using JSON operators like `->` and `->>` must successfully parse and execute when keys contain these characters, e.g. both of the following should work:

- Filtering: `?data_json->@type=eq.4`
- Selecting nested JSON keys with special characters via `select=...->...->>...` (including cases where multiple special-character keys appear in the chain, and where a cast like `::integer` is present at the end).

The parser must still reject truly reserved/delimiter characters that would make the query ambiguous or unsafe, and it must continue to produce a clear `PGRST100` parse error for those invalid cases.