PostgREST’s automatic recovery can enter a tight retry loop when the schema cache cannot be loaded (or when obtaining the PostgreSQL version fails as a prerequisite). In this situation PostgREST repeatedly retries immediately with no delay, which floods stderr/stdout logs and can consume CPU.

This can be reproduced by putting PostgREST into a “broken but running” state where schema cache queries consistently fail, for example:

1) Revoking access to `information_schema`:
```sql
revoke usage on schema information_schema from PUBLIC;
revoke usage on schema information_schema from postgrest_test_authenticator;
```
This causes repeated messages like:
- `An error ocurred when loading the schema cache`
- `{"code":"42501",..."message":"permission denied for schema information_schema"}`
followed by repeated reconnect/reload attempts.

2) Forcing schema-cache-related statements to time out (e.g., by setting an extremely low `statement_timeout` for the role used by PostgREST), which makes PostgREST spam lines like `Attempting to connect to the database...` in a rapid loop.

Expected behavior: When PostgREST fails to obtain the PostgreSQL version and/or fails to load the schema cache during startup or recovery, it should retry using an exponential backoff (or otherwise include a delay that grows between attempts) instead of retrying in a tight loop. The retry process should be unified so that failures in either “get server version” or “load schema cache” follow the same backoff-controlled retry mechanism, rather than having separate overlapping retry loops.

Also, normal startup logging should not repeatedly print `Attempting to connect to the database...` unless an actual retry is happening; that message should be reserved for retry attempts after a failure, not emitted unnecessarily during a successful first-time startup sequence.

Actual behavior: PostgREST retries schema cache loading (and in some cases repeats connection attempts) immediately and indefinitely with no backoff, causing log flooding and unnecessary load.