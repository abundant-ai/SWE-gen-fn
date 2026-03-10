PostgREST currently always starts transactions using the default isolation level (effectively equivalent to READ COMMITTED unless the client uses special handling), and it does not honor PostgreSQL’s `default_transaction_isolation` when it is set at the database role level or when it is set on a SQL function used for RPC. As a result, users cannot enforce `REPEATABLE READ` or `SERIALIZABLE` isolation for specific roles or for specific RPC functions, which makes certain concurrency-sensitive patterns (e.g., counters, concurrent reads) unreliable.

Add support so that PostgREST begins each transaction with the correct isolation level derived from PostgreSQL settings, producing SQL like:

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- request query here
COMMIT;
```

The isolation level must be determined as follows:

- If the active database role used for the request has `default_transaction_isolation` set (e.g. `ALTER ROLE my_role SET default_transaction_isolation = 'serializable';`), then all requests executed under that role must use that isolation level when opening the transaction.
- For RPC calls, if the called function itself sets `default_transaction_isolation` via a function `SET` clause (e.g. `CREATE FUNCTION ... SET default_transaction_isolation = 'serializable';`), then the RPC transaction must use the function’s isolation level.
- If both the role and the function set `default_transaction_isolation`, the function’s value must take precedence for that RPC call.

The feature must support at least these isolation levels as valid values:

- `read committed` (default)
- `repeatable read`
- `serializable`

Behaviorally, when a client calls a helper SQL function like `get_guc_value('default_transaction_isolation')` within a request executed under a role configured with `default_transaction_isolation`, the result should reflect that role’s setting, and the server should have started the transaction using `BEGIN ISOLATION LEVEL ...` matching it.

Additionally, ensure that an RPC call to a function that sets `default_transaction_isolation` results in a transaction started with that isolation level (even if the role has a different `default_transaction_isolation`).