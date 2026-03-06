When PostgREST is started with database configuration enabled (the “db-pre-config” behavior used to read settings from the database, e.g. role GUCs like `pgrst.*`), startup can fail if the pre-config SQL it runs uses identifiers that collide with PostgreSQL reserved words.

This shows up as a database error during initialization (before serving requests), typically a syntax error raised by PostgreSQL when executing the pre-config function/statement. The failure is triggered when a reserved word appears as an unquoted identifier in the query that fetches/apply pre-config values.

Expected behavior: PostgREST should successfully load database-driven configuration even if configuration keys, columns, aliases, or other identifiers involved in the pre-config query match PostgreSQL reserved words. Startup should complete normally and the loaded configuration should match the values stored in the database.

Actual behavior: PostgREST fails to start (or fails to load db-driven config) because the pre-config SQL breaks on reserved words.

Fix the db-pre-config implementation so that any database identifiers it generates/uses are properly quoted/escaped (or otherwise made safe) to avoid collisions with reserved keywords across supported PostgreSQL versions. After the fix, enabling database configuration should work with schemas/roles/settings that involve reserved words, and schema cache/routine introspection should continue to work as before.