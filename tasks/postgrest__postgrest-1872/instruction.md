When PostgREST loses its database connection (e.g., DNS failure, connection refused), it repeatedly logs retry messages such as “Database connection error. Retrying the connection.” and “Attempting to reconnect to the database in N seconds…”. These messages currently don’t include any timestamp, which makes it hard to determine when the outage began, how long recovery took, and when connectivity was restored.

Update the worker/startup and recovery logging so that each of these operational log lines is prefixed with a timestamp, in a consistent format suitable for production log correlation. The timestamp should be present for:

- Startup messages like “Attempting to connect to the database…”, “Listening on port …”, “Connection successful”, “Config re-loaded”, and “Schema cache loaded”.
- Recovery messages emitted during database reconnect loops, including the JSON-structured “Database connection error. Retrying the connection.” output and the plain-text “Attempting to reconnect to the database in N seconds…” output.

The timestamp format should match the style:

`12/Jun/2021:17:47:51 -0500: <message>`

So, for example, a reconnect attempt should look like:

`12/Jun/2021:17:47:52 -0500: Attempting to reconnect to the database in 1 seconds...`

And when a connection is re-established, it should log something like:

`12/Jun/2021:17:47:59 -0500: Connection successful`

Expected behavior: during a simulated DB outage and subsequent recovery, every relevant startup/recovery log line is timestamp-prefixed; no mixture of timestamped and non-timestamped lines should remain for these messages.

Actual behavior: the retry/error/recovery lines (and some startup lines) are emitted without any timestamp prefix, making it impossible to determine when the connection was lost or recovered from logs alone.