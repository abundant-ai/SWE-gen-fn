When a client sends a mutation request with the HTTP header `Prefer: tx=rollback`, PostgREST runs the request inside a transaction that is rolled back at the end so the database is not changed, but the response can still include `return=representation` data.

Currently, if the mutation would violate a deferred constraint (e.g., a DEFERRABLE unique constraint or a deferred constraint trigger that only fires at transaction end), PostgREST may return a successful response (including the representation of the would-be inserted/updated row) under `tx=rollback`. The same request under `Prefer: tx=commit` correctly fails with a PostgreSQL error.

This is incorrect: `Prefer: tx=rollback` must still execute deferred constraints/constraint triggers and surface any resulting errors, even though the transaction will be rolled back afterward.

Reproduction example:
- Call an endpoint that triggers a deferred unique-constraint violation (for example by attempting to insert a duplicate key into a table with a DEFERRABLE unique constraint), using `Prefer: return=representation`.
- With `Prefer: tx=commit`, the request fails with status `409` and a PostgreSQL error payload like:

```json
{
  "hint": null,
  "details": "Key (col)=(1) already exists.",
  "code": "23505",
  "message": "duplicate key value violates unique constraint \"deferrable_unique_constraint_col_key\""
}
```

- With `Prefer: tx=rollback`, the current behavior may return success (e.g., `201`/`200`) and include the inserted/updated representation, even though the operation is invalid.

Expected behavior:
- For mutation requests, `Prefer: tx=rollback` must behave like `tx=commit` with respect to constraint checking and error reporting.
- If a deferred constraint (or constraint trigger) would fail at transaction end, the request must fail under `tx=rollback` as well, returning the same PostgreSQL error (including SQLSTATE like `23505`) and the appropriate HTTP status mapping (e.g., `409` for unique violations).
- The response header `Preference-Applied: tx=rollback` should still be present when `tx=rollback` is requested.
- Even when the request fails due to deferred constraints, the transaction must still be rolled back so no data persists.

Implement the missing behavior so that before PostgREST rolls back a `tx=rollback` transaction, deferred constraints are forced to run (equivalent to making deferred constraints immediate for the remainder of the transaction) so that any violations are detected and returned to the client rather than being silently skipped by the rollback path.