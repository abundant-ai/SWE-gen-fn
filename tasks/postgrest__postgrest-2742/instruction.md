PostgREST currently only applies PostgreSQL role GUC settings that are set on the connection role (typically the `authenticator` role) because those settings are loaded at login time. This means per-request impersonation of a database role (e.g., switching to `anon` or `web_user`) does not cause role-specific settings like `statement_timeout` to take effect.

Reproduce the problem by configuring different per-role settings in Postgres, for example:

```sql
ALTER ROLE anon SET statement_timeout = 500;
ALTER ROLE web_user SET statement_timeout = 3000;
```

Then make requests as each role (via the normal PostgREST role switching mechanism, e.g. JWT role claim or anon role). Even though the effective SQL role changes, `current_setting('statement_timeout')` remains whatever was established for the original connection/login role, and long-running queries are not constrained by the target role’s `statement_timeout`.

The server must support a configuration option that lists which role settings should be applied at the start of every transaction (e.g. `db-tx-settings = 'statement_timeout'`, and also supporting multiple settings like `db-tx-settings = 'statement_timeout, plan_filter.statement_cost_limit'`). For each request/transaction, after the request role is determined, PostgREST should fetch the configured settings for that target role from PostgreSQL (from role/database role settings, as stored in `pg_db_role_setting`) and apply them within the transaction so they affect the remainder of that transaction.

Expected behavior:
- When `db-tx-settings` includes `statement_timeout` and the target role has `ALTER ROLE <role> SET statement_timeout = ...`, then within the transaction handling a request for that role, `current_setting('statement_timeout')` should reflect that role-specific value.
- Different roles must observe their own configured values on their respective requests (e.g. anon sees 500ms, web_user sees 3000ms).
- If a listed setting has no value for the role, it should not erroneously override or set it to an empty value.
- The mechanism must work reliably across pooled connections: settings must be applied per transaction/request and not leak between requests of different roles.

Actual behavior to fix:
- Per-role `ALTER ROLE ... SET ...` values other than those on the connection role are not being picked up, so `statement_timeout` (and other GUCs) are not enforced for impersonated roles.

Implement the configuration-driven transaction setting application so that role-specific GUCs can be enforced per request, enabling use cases like per-role query timeouts and extension-specific settings (e.g. `plan_filter.statement_cost_limit`).