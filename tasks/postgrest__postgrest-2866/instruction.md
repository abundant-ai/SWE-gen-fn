Inserting or updating rows that include fixed-length PostgreSQL types (notably character(n) and bit(n)) is broken: values that exactly match the declared length can be rejected with a database error like `22001` and message `value too long for type character(1)`. This regression is observable after upgrading to a newer PostgREST version (e.g., 11.1.0), and it happens even though running the equivalent SQL directly against PostgreSQL succeeds.

For example, given a table with a foreign key column declared as `char(2)`, an API call like:

```js
.insert({ country: "DE" })
```

should successfully insert the row, but instead fails with:

```json
{
  "code": "22001",
  "details": null,
  "hint": null,
  "message": "value too long for type character(1)"
}
```

Similarly, updates (PATCH) that set `char(n)` or `bit(n)` columns to strings of the correct length should succeed but can fail due to the server treating the column as if it had length 1.

The server must correctly handle fixed-length columns that have a declared length, ensuring that both INSERT and UPDATE requests bind/coerce values using the proper column type and length so that values of length `n` are accepted for `character(n)` and `bit(n)` (and rejected only when they truly exceed the defined length). The behavior should match what PostgreSQL accepts for direct SQL `INSERT`/`UPDATE` on the same schema.

Repro scenario to validate:
1. Create a table with a `character(2)` (or `char(2)`) column and insert via the REST API a 2-character string (e.g., "DE"). It should return success (201 for insert, 204/200 depending on return preferences) rather than `22001`.
2. Do the same for `bit(2)` (or other `bit(n)`) columns, ensuring values that match the defined length are accepted during insert and update.
3. Ensure that values that exceed the defined length still correctly fail with PostgreSQL’s length error.