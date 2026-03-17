PostgREST’s health check currently reports healthy (HTTP 200) even when the schema cache refresh has failed. This can happen at startup (e.g., due to a database structure parsing problem such as failures around parsing `pg_node_tree` via JSON) and can also happen later when an otherwise-running instance attempts to refresh its schema cache.

The health endpoint must take the schema cache refresh state into account. When the last schema cache refresh attempt failed, the health check should respond with HTTP 503 (unhealthy) instead of HTTP 200. When the schema cache refresh succeeds, the health check should report healthy (HTTP 200).

At the moment, startup behavior and runtime behavior are inconsistent: the application may fail requests at startup when it cannot load schema cache, but the health check can still return 200, and if a refresh fails after the server is already running, the main application may continue serving using a stale schema cache while the health check does not reflect the failure.

Implement persistent tracking in application state for whether the most recent schema cache refresh succeeded or failed, and have the health check consult that state. The result should be:

- If schema cache has never successfully loaded, health should be HTTP 503.
- If schema cache previously loaded successfully but the most recent refresh attempt failed, health should be HTTP 503 until a subsequent refresh succeeds.
- If the most recent refresh attempt succeeded (and schema cache is present/valid), health should be HTTP 200.

This should work both at startup and after startup when schema cache refresh is triggered while the server is running, so that operators can detect schema-cache-related failures via the health endpoint without needing to infer it from other behavior.