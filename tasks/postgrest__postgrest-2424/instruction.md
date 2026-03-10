Bulk updates intended to update multiple rows with different values in a single request are currently unsafe/incorrect and must not be supported in a way that breaks normal mutation semantics or database safety rules.

When clients try to perform a “bulk update” by sending an array of objects to an endpoint (e.g. targeting a table like `/example`) and using `Prefer: resolution=merge-duplicates` (or similar upsert-style behavior), PostgREST can end up treating this as an insertion/merge operation rather than a true update. In real schemas with `NOT NULL` columns, this fails when the payload only includes a subset of columns.

For example, given a table with columns `(pk primary key, name NOT NULL, value NOT NULL)`, a client may send:

```json
[
  {"pk": 1, "name": "example"},
  {"pk": 2, "name": "second"}
]
```

and attempt to apply it in one request. The request fails with an error like:

`null value in column "value" violates not-null constraint`

because missing fields are effectively treated as `NULL` during the merge/insert-style operation.

PostgREST should not attempt to support “proper bulk update via PATCH” by accepting an array payload that results in this kind of constraint-violating merge behavior. Instead, array payload PATCH-based bulk updates should be rejected or treated in a way that does not try to insert/merge rows and does not cause omitted columns to be written as NULL.

Additionally, PostgREST must continue to behave correctly when the PostgreSQL `pg-safeupdate` extension is enabled:

- A full-table `PATCH` without any filter/condition must fail with HTTP 400 and a JSON error payload containing:

```json
{
  "code": "21000",
  "details": null,
  "hint": null,
  "message": "UPDATE requires a WHERE clause"
}
```

- If a filter is present (e.g. `id=gt.0`), the same kind of `PATCH` must be allowed and should return 204 with appropriate headers including `Content-Range` and `Preference-Applied` when `Prefer: tx=commit` is used.

Implement/restore the request handling and query-building behavior so that:
1) the reverted bulk-update-via-array semantics are not exposed as a supported feature (preventing the NOT NULL violation scenario above from being presented as a “bulk update” capability), and
2) the existing filter parsing behavior (including the refactor around `qsFiltersRoot`) continues to work, and
3) pg-safeupdate error handling and success behavior for PATCH/DELETE are preserved exactly, including the specific error message and HTTP status described above.