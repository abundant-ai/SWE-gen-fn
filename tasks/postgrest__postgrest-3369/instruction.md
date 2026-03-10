When PostgREST reloads its schema cache (e.g., after a NOTIFY-triggered reload), requests that depend on the schema cache—such as queries that use resource embedding—become extremely slow because they block waiting for the reload to complete. This is especially noticeable on complex databases where schema cache querying takes a long time.

Reproduction scenario:
1) Run PostgREST against a large/complex schema (a schema where schema cache querying is slow).
2) Trigger a schema cache reload via a NOTIFY mechanism exposed through an RPC endpoint (e.g., calling an RPC like /rpc/notify_pgrst that causes a NOTIFY pgrst).
3) While the reload is in progress, issue a request that requires the schema cache for planning, such as an embedded resource request:
   GET /tpopmassn?select=*,tpop(*)

Actual behavior:
- The request waits for the schema cache reload to finish and takes on the order of 10+ seconds to plan.
- With server timing enabled, the Server-Timing header shows a very large duration for the planning phase, e.g.:
  Server-Timing: ... plan;dur=12828.9, ...

Expected behavior:
- Requests should not be forced to wait for a schema cache reload. While a new schema cache is being loaded, PostgREST should continue serving requests using the previously loaded (stale) schema cache, and then switch to the newly loaded cache once it’s ready.
- In other words, schema cache reload should be non-blocking for in-flight/new requests that need schema metadata; those requests should plan using the last known good cache rather than stalling on the reload.

Additionally, the behavior should be observable/understandable in logs or metrics: it should be clear that schema cache reload is happening in the background and that requests are not being queued behind it.