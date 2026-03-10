When inserting rows via PostgREST using the header `Prefer: missing=default`, columns that are omitted from the JSON payload should use their database defaults. This currently fails for columns whose type is a PostgreSQL DOMAIN that has a default value and a NOT NULL constraint.

In this scenario, omitted DOMAIN-typed columns are being coerced to `null` during the INSERT process (due to how missing fields are expanded), which violates the domain’s NOT NULL constraint and/or results in `null` being stored where the domain default should have been applied.

Reproduction example (simplified):

1) In PostgreSQL, define a DOMAIN type with a default and NOT NULL behavior, and use it in a table column. For instance, a domain like `non_null_text` based on `text` with `NOT NULL` and a `DEFAULT 'x'` (or equivalent), and then a table column `col non_null_text`.

2) Send an INSERT request that omits `col` and includes `Prefer: missing=default`.

Expected behavior:
- The INSERT should succeed.
- The omitted DOMAIN column should be filled with its declared default value.
- Domain constraints (especially NOT NULL) must be respected, meaning the missing value must not be treated as an explicit null.

Actual behavior:
- The request fails because the missing DOMAIN column is coerced to `null`, violating the domain constraint.
- Typical PostgreSQL error observed is of the form: a domain check/NOT NULL violation indicating the value is null (e.g., a NOT NULL violation on the domain or domain constraint failure), even though `missing=default` was requested.

Fix required:
- Ensure that `Prefer: missing=default` causes omitted fields to be treated as “use DEFAULT” rather than being materialized as `null`, including for columns whose types are DOMAINs with defaults.
- The behavior should be consistent for both single-row JSON objects and JSON arrays of objects.
- The fix must not regress existing behavior for non-domain columns, explicit `null` values (which should still be treated as explicit nulls), or requests without `Prefer: missing=default`.
