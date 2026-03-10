PostgREST currently hoists all `SET` clauses defined on a PostgreSQL function (e.g., `CREATE FUNCTION ... SET search_path TO ...`) to the transaction level when the function is invoked via RPC. This behavior is a regression: function-local settings meant to apply only during that function’s execution are being applied to the entire transaction, which can break subsequent queries in the same request (for example, computed fields or other follow-up queries that assume the original `search_path`).

Example problematic function:

```sql
create function do_something_dangerous() returns something
security definer
set search_path to pg_catalog, pg_temp
language plpgsql as $$
...
$$;
```

Expected behavior: calling an RPC should not automatically apply every function `SET` setting to the whole transaction. Only an explicitly allowed subset of function settings should be “hoisted” to transaction scope.

Actual behavior: all function `SET` settings are hoisted, including settings like `search_path`, and potentially unsafe ones such as `role` if present (e.g., `SET ROLE TO ...`). This can cause security and correctness issues.

Implement a new configuration option named `db-hoisted-tx-settings` that controls which function `SET` parameters are allowed to be hoisted to the transaction. When PostgREST prepares the transaction for an RPC call, it must filter the function’s settings and apply only those whose parameter names are present in `db-hoisted-tx-settings`.

Requirements:

- `db-hoisted-tx-settings` is a comma-separated list of GUC/setting names (e.g., `statement_timeout,plan_filter.statement_cost_limit,default_transaction_isolation`).
- Only settings whose names match the allowlist are hoisted to the transaction level.
- Settings not on the allowlist (notably `search_path`) must remain function-local and must not affect the rest of the transaction/request.
- The default value of `db-hoisted-tx-settings` must be `statement_timeout,plan_filter.statement_cost_limit,default_transaction_isolation`.
- The configuration must be loadable from the standard PostgREST configuration sources and appear when dumping/printing the effective configuration.

After this change, RPCs that rely on function-local `SET search_path` should no longer break subsequent SQL executed as part of the same request because the transaction `search_path` should remain unchanged unless it was explicitly allowlisted.