When PostgREST runs with a configured connection pool (e.g., `db-pool = 60`), operators have insufficient visibility into what the pool is doing when connections are created, reaped, or terminated. In production incidents where the authenticator role unexpectedly exceeds the configured pool size (and can even hit PostgreSQL `max_connections`), the only symptom may be generic retries like:

```
{"code":"PGRST000","details":"FATAL:  remaining connection slots are reserved for non-replication superuser connections\n","hint":null,"message":"Database connection error. Retrying the connection."}
```

Additionally, under some pool/connection-error conditions PostgREST can respond with an empty error payload, for example a 400 with:

```
{ code: '', details: null, hint: null, message: '' }
```

This makes it difficult to determine whether the pool’s reaper/idle-timeout/lifetime logic is running and whether connections are being correctly recycled.

Implement connection pool event logging at `log-level=info` so that pool lifecycle events become visible in normal operational logs. The logging should cover at least these events with a stable, readable message format: when a connection is being established, when it becomes available for use, and when it is terminated along with a clear termination reason (e.g., max idle time, max lifetime, explicit release, network error). Example log lines should look like:

```
Connection <uuid> is being established
Connection <uuid> is available
Connection <uuid> is terminated due to max idletime
Connection <uuid> is terminated due to network error
Connection <uuid> is terminated max lifetime
Connection <uuid> is terminated due to release
```

The goal is that, when the pool reaper runs and removes/recycles idle or aged connections, these actions are observable in logs without requiring debug-level logging.

Also ensure that when a database/pool failure happens and PostgREST returns an error response, the error JSON is never “empty” (no blank `code`/`message`). Error responses must include a non-empty error `code` and a non-empty human-readable `message` so clients do not see `{ code: '', ... message: '' }` even transiently during pool recovery/retry scenarios.