PostgREST’s RPC endpoint has a regression where SQL functions declared with a single-column `RETURNS TABLE(...)` return type are serialized incorrectly.

When calling an RPC that returns `RETURNS TABLE(test text)` (i.e., a set of rows with exactly one named column), PostgREST should return a JSON array of objects keyed by the column name. Instead, in newer versions the response becomes a JSON array of bare scalar values (strings), losing the column name.

Reproduction example:

1) Create a function that returns a set via a single-column `RETURNS TABLE`:

```sql
CREATE FUNCTION public_api.test() RETURNS TABLE(test TEXT) AS $$
  WITH series AS (
    SELECT generate_series(0, 10) AS gen
  )
  SELECT 'Test ' || series.gen AS test
  FROM series;
$$ LANGUAGE sql;
```

2) Call it via RPC:

```bash
curl -X POST http://127.0.0.1:3000/rpc/test -H "Accept: application/json"
```

Expected JSON response (object style, preserving the column name):

```json
[{"test":"Test 0"}, {"test":"Test 1"}, {"test":"Test 2"}]
```

Actual JSON response (incorrect scalar style):

```json
["Test 0", "Test 1", "Test 2"]
```

This incorrect scalar serialization only happens for `RETURNS TABLE` with exactly one column; `RETURNS TABLE(a ..., b ...)` should continue to return an array of objects as it already does. The fix should ensure that RPC responses use object-style JSON whenever the function’s output has named fields, including the special PostgreSQL case of a single-column `RETURNS TABLE`.

After the fix, both GET and POST calls to `/rpc/<function>` for such functions must return an array of objects keyed by the table column name, not an array of scalars.