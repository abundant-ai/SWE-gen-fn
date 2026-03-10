PostgREST currently only applies the function-level setting `statement_timeout` when calling a PostgreSQL function that declares per-function settings via `CREATE FUNCTION ... SET <guc> TO <value>`. Other function settings are ignored, which prevents users from relying on function-scoped GUCs such as custom/extension settings or core settings like logging knobs.

Example:

```sql
CREATE OR REPLACE FUNCTION myfunc()
RETURNS void AS $$
  SELECT pg_sleep(3);
$$
LANGUAGE SQL
SET plan_filter.statement_cost_limit TO 1300;
```

Expected behavior: when PostgREST invokes an RPC function, it must apply *all* settings declared on that function as **transaction-scoped settings** for the duration of the request/transaction (i.e., equivalent to `SET LOCAL` behavior). This should not be limited to `statement_timeout`; any function `SET` entries returned by PostgreSQL for that routine must be applied.

Actual behavior: only `statement_timeout` takes effect; other function settings are not applied, so querying the current value inside the function (or via a helper like `get_guc_value('some.setting')`) returns the session/default value instead of the function’s declared value.

The fix should ensure that:
- All per-function settings declared via `CREATE FUNCTION ... SET ...` are applied for RPC execution.
- Settings are transaction-scoped (do not leak to subsequent requests).
- If a function has multiple settings, they should all be applied.
- The behavior works for schema-qualified functions as well (e.g., `v1.get_guc_value(...)`).
- When applying a setting requires privileges, PostgREST should handle this in a predictable way (either by successfully applying when permitted, or failing the request with a clear database error rather than silently ignoring the setting).