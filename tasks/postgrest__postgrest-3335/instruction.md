When PostgREST is running against a large/complex database schema, reloading the schema cache (e.g., via NOTIFY on the configured channel) can cause unrelated client requests that depend on the schema cache—such as requests using resource embedding—to become extremely slow. During the reload window, these requests block waiting for the new schema cache to finish building, leading to multi-second delays (e.g., the Server-Timing header shows a very large "plan" duration, on the order of ~10–13 seconds).

The server should not stall normal request handling during a schema cache reload. Instead, while a new schema cache is being recomputed, PostgREST should continue serving requests using the previously loaded (stale) schema cache, and then switch over to the fresh cache once it is ready.

Reproduction scenario:
- Run PostgREST with server timing enabled (PGRST_SERVER_TIMING_ENABLED=true) and a schema that is slow to introspect.
- Make a request that requires schema cache usage, for example: GET /tpopmassn?select=*,tpop(*)
- Trigger a schema cache reload via an RPC that issues NOTIFY pgrst (or otherwise sends the reload notification).
- Shortly after triggering the reload, repeat the same embedding request.

Current behavior:
- The request succeeds (HTTP 200) but becomes very slow during the reload window.
- The response includes a Server-Timing header where the "plan" timing is very large (seconds).

Expected behavior:
- Requests that depend on the schema cache must not wait for the schema cache reload to complete.
- The request should remain fast even while a reload is in progress.
- In particular, the "plan" timing reported in the Server-Timing header for GET /tpopmassn?select=*,tpop(*) should stay under 2.0 seconds both on the initial request and during/after triggering a schema cache reload.

Implement the schema-cache reload logic so that reload happens in the background and does not block request planning, by ensuring that request planning continues to use the last successfully loaded schema cache until the new schema cache has finished loading and can be swapped in.