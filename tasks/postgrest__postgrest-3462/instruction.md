When PostgREST is run against a PostgreSQL read replica, schema cache reloading via LISTEN/NOTIFY does not work. Read replicas do not support LISTEN/NOTIFY, and they also can’t create the event triggers commonly used to emit NOTIFY events. As a result, deployments that point PostgREST at a replica cannot rely on NOTIFY-based reloads.

PostgREST currently uses the main database connection settings (the same URI/connection string used for normal request queries) for both request handling and for the LISTEN channel that watches for reload notifications. In a primary/replica setup this means the LISTEN connection also ends up on the replica, where LISTEN is unsupported, so no reload notifications are received.

Add support for configuring a dedicated connection string/URI for the LISTEN/NOTIFY channel so that PostgREST can serve queries from a replica while keeping the notification listener connected to the primary.

Expected behavior:
- A new configuration option named `db-channel-uri` is supported.
- If `db-channel-uri` is not set, PostgREST behaves exactly as before and uses the same value as `db-uri` for the LISTEN channel.
- If `db-channel-uri` is set (for example: `db-channel-uri = "postgres://authenticator:secret@primary:5432/postgres?parameters=val"`), PostgREST uses this URI exclusively for the LISTEN/NOTIFY connection, while normal requests continue using `db-uri`.
- This enables NOTIFY-based schema cache reloads to function in deployments where `db-uri` points to a read replica but `db-channel-uri` points to the primary.

The change must work in a primary/replica environment where a PostgREST instance connected to the primary reports it is not a replica, and a PostgREST instance configured to connect to a replica reports it is a replica, while both can still successfully serve read queries like `GET /items?select=count`.

Ensure the configuration is exposed consistently (same style as `db-uri`), including environment-variable configuration, and that the listener uses the correct connection even when the main connection may resolve to a replica host.