PostgREST currently mishandles `in` filters when the list values contain double quotes (`"`) and backslashes (`\`). When a client tries to filter a text column for values that include a literal double quote, PostgREST generates a malformed PostgreSQL array literal and PostgreSQL returns an error like:

```
{"message":"malformed array literal: \"{\"\"\"}\"","code":"22P02","details":"Unexpected array element."}
```

Reproduction example:

1) Given a table with a text column containing a literal double quote value:

```sql
CREATE TABLE t(data text);
INSERT INTO t(data) VALUES ('"');
```

2) Calling the API with an `in` filter using a URL-encoded double quote:

```
GET /t?data=in.(%22)
```

should correctly match the row where `data` is `"` and return a normal JSON response, but instead it fails with the malformed array literal error above.

Similarly, values that include multiple quotes also fail, e.g.:

```
GET /t?data=in.(%22%22%22)
```

In addition to fixing support for literal `"` and `\` values inside `in.(...)`, PostgREST should also support backslash escaping inside double-quoted `in` values. The following query forms must be accepted and interpreted as shown:

- `?col=in.("Double\"Quote")` should be treated as a single `in` value containing `Double"Quote` (a literal `"` inside the value).
- `?col=in.("Back\\slash")` should be treated as a single `in` value containing `Back\slash` (a literal backslash inside the value).

Backslashes that do not form a recognized escape sequence inside double quotes should be passed through without special handling; for example:

- `?col=in.("\a\b\c")` should behave the same as `?col=in.(abc)` (i.e., the backslashes are not preserved and the characters `a`, `b`, `c` are used as the value).

After the fix, `in` filtering must no longer produce malformed PostgreSQL array literals for these inputs, and requests using these `in` filter forms should succeed (no 22P02 errors) and correctly match rows based on the intended literal string values.