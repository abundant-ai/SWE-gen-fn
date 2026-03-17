Ecto currently produces incorrect SQL when a JSON navigation path is provided dynamically (as a parameter/interpolated value) inside a `fragment/2+` expression. Specifically, when the JSON field and the JSON path are both passed as fragment arguments, Ecto treats the JSON path as a normal string parameter and quotes it as a single SQL string literal, which results in extra quoting inside the generated SQL and wrong query semantics.

For example, these two queries should be semantically equivalent and generate equivalent SQL:

```elixir
# static path in SQL
from(b in Book,
  where: fragment("(meta -> 'formats' -> 'digital')::boolean = false")
)

# dynamic field and dynamic path
from(b in Book,
  where: fragment("(? -> ?)::boolean = false", b.meta, "'formats' -> 'digital'")
)
```

However, today the second form generates SQL like:

```sql
(b0."meta" -> '''formats'' -> ''digital''')::boolean = false
```

The JSON path portion is incorrectly wrapped/escaped as a single quoted string literal (effectively turning the entire `"'formats' -> 'digital'"` into one value), which changes the meaning of the JSON operator usage and can return wrong results.

Ecto should allow dynamically specifying the entire JSON path in a way that generates the same SQL as if the JSON path had been written directly in the fragment string. When a JSON path is provided dynamically, Ecto should treat it as a JSON-path expression (not as a normal string value) so that the resulting SQL uses the `->` navigation properly without adding extra quotes.

This should work for typical multi-segment JSON paths (e.g. `"'formats' -> 'digital'"`) and should behave consistently with other supported JSON path APIs, such as building expressions like `json_extract_path(field, ["a", "b"])` or bracket navigation like `field["a"]["b"]`, while preserving compile-time validation rules where applicable. If an invalid JSON path value is provided, Ecto should raise an `Ecto.Query.CompileError` with an appropriate message rather than generating malformed SQL.