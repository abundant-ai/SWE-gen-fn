PostgREST’s database listener and schema cache loading can enter a tight, endless retry loop with no exponential backoff when the database operations repeatedly fail quickly (for example, due to very low `statement_timeout` or when running against a read replica where `LISTEN` is not allowed).

Reproduction example: if the database role used by PostgREST has a very small statement timeout (e.g. `ALTER ROLE postgrest_test_authenticator SET statement_timeout TO '10'`), starting PostgREST causes repeated connection/schema cache reload attempts that log continuously with no delay, producing lines like:

```
Attempting to connect to the database...
Attempting to connect to the database...
Attempting to connect to the database...
...
```

A similar problem occurs for notification listening in replica/recovery scenarios: when PostgREST attempts to listen on the notification channel (default channel name like "pgrst") and PostgreSQL rejects it (e.g. `ERROR: cannot execute LISTEN during recovery`), PostgREST should not retry in a tight loop. Instead it must retry with exponential backoff, emitting logs like:

```
Failed listening for notifications on the "pgrst" channel. ERROR: cannot execute LISTEN during recovery
Retrying listening for notifications in 1 seconds...
Retrying listening for notifications in 2 seconds...
Retrying listening for notifications in 4 seconds...
...
```

Expected behavior:
- When the schema cache load or the notification LISTEN fails repeatedly, PostgREST must apply exponential backoff between retries rather than looping without delay.
- The backoff should start small (e.g. 1 second) and grow on consecutive failures (e.g. 1, 2, 4, …) up to a reasonable cap.
- The system must remain responsive to eventual recovery: once PostgreSQL stops erroring (e.g. replica finishes recovery or the transient timeout condition is removed), PostgREST should resume normal operation.

Actual behavior:
- Under the conditions above, PostgREST retries immediately in an endless loop, spamming logs and consuming resources, with no backoff delay between attempts.

Implement the retry behavior so that the listener/notification wait loop and schema cache load failures are retried using exponential backoff rather than immediate rapid retries, while preserving the existing behavior that some failures (e.g. invalid credentials) should still fail fast and exit rather than retry indefinitely.