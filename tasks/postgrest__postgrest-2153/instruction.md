PostgREST currently includes PostgreSQL routine-like objects that it cannot actually execute as RPC endpoints in both its schema cache and the generated OpenAPI output. In particular, stored procedures are surfaced as `/rpc/<name>` endpoints, but invoking them fails because PostgREST issues a `SELECT`-style function call rather than `CALL`, and PostgreSQL returns an error like:

```
code: "42809"
hint: "To call a procedure, use CALL."
message: "<schema>.<name>(...) is a procedure"
```

Similarly, aggregates and window functions are also exposed in the schema cache/OpenAPI even though calling them through the RPC mechanism is not meaningful/useful.

The schema cache and OpenAPI generation should only expose RPC endpoints for callable functions that PostgREST can execute correctly. Stored procedures must not appear as RPC endpoints in OpenAPI output (and should not be part of the cached routine list used to build RPC routes) until procedure support is implemented. Aggregates and window functions must also be excluded.

Concretely:
- If the database contains a stored procedure like `items_create_new_item_for_category(category_id bigint, item_name varchar)`, OpenAPI must not include `/rpc/items_create_new_item_for_category`.
- Aggregates and window functions must not be listed as RPC endpoints.
- Regular functions that are supported as RPCs must continue to be included and work as before.

After the change, generating OpenAPI should no longer advertise endpoints that would inevitably fail at runtime with `42809` (procedure) or other errors stemming from non-callable/non-RPC-appropriate routine kinds.