When PostgREST starts with a large schema (slow schema cache load), the admin server readiness endpoint `/ready` can incorrectly report that the service is ready while the schema cache is still loading and not yet populated.

Reproduction scenario:
- Configure PostgREST with an admin server port (e.g. `PGRST_ADMIN_SERVER_PORT=3001`) and a large schema / slow schema cache load (for example by using a big schema and a small DB pool).
- Start PostgREST and observe that the log shows the schema cache query starting, but it may not yet log a completed "Schema cache loaded" message.
- While the schema cache is still loading, call the admin endpoint:
  
  ```bash
  curl -i http://localhost:3001/ready
  ```

Actual behavior:
- `/ready` responds with `HTTP/1.1 200 OK` even though the schema cache is not fully loaded.

Expected behavior:
- `/ready` must only return success (200) once the schema cache has finished loading and is fully available for requests that require it.
- While the schema cache is still loading (including any intermediate state where a schema cache value may exist but is not yet “loaded/complete”), `/ready` should indicate not-ready (non-200 response).

This incorrect readiness signal leads to clients or orchestrators proceeding as if the service is ready, and to requests arriving before the schema cache is usable. In particular, requests that depend on the schema cache (e.g. queries that require relationship/resource embedding like `GET /tpopmassn?select=*,tpop(*)`) must not proceed as if everything is ready until the schema cache has actually finished loading.

Implement the fix so that readiness reflects the true loaded state of the schema cache, not merely the presence of a schema-cache container/value during the loading phase. Ensure that when PostgREST is started without waiting for readiness and a request that uses schema-cache-dependent features is sent during the load, the request waits for schema cache completion and then succeeds; and that the “planning” timing reported via the `Server-Timing` header reflects the waiting time (i.e., it is very large when the schema cache is still loading, and small when readiness has been confirmed beforehand).