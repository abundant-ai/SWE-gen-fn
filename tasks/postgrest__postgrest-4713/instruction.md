PostgREST currently creates and stores listening sockets as part of application state initialization, even in cases where the process will never start an HTTP server (for example, command-line invocations that only print configuration or inspect the database). This causes sockets to be created/bound when they are not needed and can fail or block in environments where the configured address/port is unavailable.

In addition, PostgREST cannot start listening only after the initial schema cache load completes, because the sockets are created inside the application-state initialization path. This makes it impossible to defer binding the public/admin ports until after the system is ready.

Fix the initialization flow so that listening socket creation/management is owned by the main server startup logic rather than the application state. Sockets must be created only when starting the actual HTTP services and then passed into both the main server (Warp) and the admin application startup. Application state initialization (including schema cache initialization via functions like querySchemaCache and database introspection like queryPgVersion) must be able to run without creating/binding any listening sockets.

Expected behavior:
- Running non-server commands (e.g., configuration/schema-related CLI actions) must not create or bind listening sockets at all.
- Starting the server via PostgREST.App.postgrest must be able to perform initial setup (including schema cache loading) before binding/listening on the configured sockets.
- The admin interface and main HTTP server must still start normally when requested, using sockets provided by the server startup layer (not stored/created in AppState).

Actual behavior to address:
- Listening sockets are created during AppState initialization even when no server is started.
- Deferring listening until after schema cache load is not possible because socket creation requires AppState.