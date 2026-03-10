Calling PostgreSQL functions through PostgREST RPC currently does not honor a `statement_timeout` defined on the function itself (via `CREATE FUNCTION ... SET statement_timeout TO ...`). In PostgreSQL, a function-level `SET statement_timeout` is not automatically applied to the statement that invokes the function, so `SELECT my_func()` can run longer than the function’s configured timeout.

This causes unexpected behavior for RPC endpoints: a function like

```sql
create or replace function my_func() returns void as $$
  select pg_sleep(3);
$$ language sql set statement_timeout to '1s';
```

when called through the RPC endpoint should time out quickly, but instead it completes successfully after ~3 seconds.

PostgREST should apply the function’s `statement_timeout` at the start of the transaction for RPC calls, so that the timeout is enforced for the duration of the RPC request. This should behave similarly to how PostgREST already applies other function/role transaction settings (for example, default transaction isolation settings).

Expected behavior: When invoking an RPC that resolves to a function with `SET statement_timeout = '1s'`, the RPC should fail by canceling the statement due to statement timeout (surfacing PostgreSQL’s timeout error), rather than completing successfully after exceeding that limit.

Also ensure this timeout application is scoped to the RPC transaction (i.e., set locally for the transaction handling the RPC call) and that it correctly overrides any role-level `statement_timeout` for that RPC execution.