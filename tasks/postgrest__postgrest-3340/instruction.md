When PostgREST receives a PostgreSQL LISTEN/NOTIFY message on the configured channel (commonly "pgrst") requesting a reload (for example payloads like "reload schema" or "reload config" sent via pg_notify), the server should log a clear informational message indicating that the channel received the reload request, and then proceed with the appropriate reload behavior.

Currently, LISTEN notifications trigger the reload actions but the logs do not clearly show that the reload was initiated by a notification, making it hard to understand why a schema cache reload or config reload happened.

Update the notification handling so that, upon receiving a notification, PostgREST emits a log line like:

- For schema reload: The "pgrst" channel got a schema cache reload message
- For config reload: The "pgrst" channel got a config reload message

Then the usual subsequent logs should appear depending on the reload type. For a schema cache reload initiated via notification, the sequence should include reconnect/reload activity (e.g., attempting to connect, successfully connected, config reloaded if applicable, schema cache queried/loaded). For a config reload message, it should log the notification receipt and then log that the config was reloaded.

The logging should include the actual channel name used, and it should only log these messages when a LISTEN notification is received (not during startup or periodic reloads).