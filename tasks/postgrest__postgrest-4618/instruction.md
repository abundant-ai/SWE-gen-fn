When PostgREST successfully establishes its dedicated PostgreSQL LISTEN/NOTIFY “listener” connection, it emits a log entry confirming the connection. That log entry currently does not include enough PostgreSQL version information to diagnose issues related to server version, protocol features, or mismatched connection targets.

Update the successful listener-connection log message to include PostgreSQL version details of the listener connection. The version details must be obtained from the listener connection itself (not from configuration assumptions), and should be present in the log line emitted immediately after the listener connection is established.

Expected behavior: after startup (or after any event that re-establishes the listener connection), the logs include a listener-connection success message that also reports PostgreSQL version details (e.g., the server version number and/or a human-readable version string) corresponding to that listener connection.

Actual behavior: the listener-connection success message is logged without PostgreSQL version details.

This must work regardless of how the database connection is configured (e.g., via a full db-uri, via environment/libpq parameters, or via db-uri read from stdin), and it must not break connection establishment or existing startup behavior.