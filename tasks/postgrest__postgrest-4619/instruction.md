When performing a mutation (UPDATE/DELETE) with a returning representation (using `select=...`) and the request uses complex boolean logic via `or`/`and` (including nested or negated forms), PostgREST generates an extra filtering clause for the post-mutation SELECT that reuses the original boolean filters. This can incorrectly filter out the rows that were successfully mutated, because the boolean condition is evaluated against the *new* values instead of the pre-mutation values.

Reproduction example:

A table:
```sql
create table jobs (
  id uuid primary key default gen_random_uuid(),
  started_at timestamp with time zone
);
```

A request that updates `started_at` but only for rows where `started_at` is NULL or older than a cutoff, while also requesting the updated row back:
- Update: `started_at = now()`
- Filters: `id = <id>` and `or=(started_at.is.null,started_at.lt.<cutoff>)`
- Return: `select=id,started_at`

Expected behavior: If the row matches the filter conditions *before* the update, the update should happen and the response should include the updated row (with `started_at` set to now).

Actual behavior: The update happens (or at least the mutation CTE returns the row), but the final response body is `null` / empty because the generated query applies the `or`/`and` boolean filter again when selecting from the mutation result. Since `started_at` has already been set to `now()`, the condition `(started_at IS NULL OR started_at < cutoff)` becomes false and the row is filtered out.

This same class of bug applies broadly to mutation requests that:
1) request a returned representation (via `select`), and
2) use `or`/`and` parameters (including `not.or`, nested `and(...)` inside `or(...)`, and combinations with traditional filters).

Fix the query generation so that for mutations with a returned representation, the returned rows are not incorrectly re-filtered using `or`/`and` boolean logic against the post-mutation values. The returned representation should reflect the rows actually affected by the mutation, while still respecting the normal mutation target filters used to decide which rows to mutate.