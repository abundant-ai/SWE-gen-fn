PostgREST can crash or terminate a connection due to asynchronous exceptions (notably `StackOverflow`) without producing any log output, making failures appear as silent “empty reply from server” errors to clients.

Reproduction:
1) Start PostgREST against a large schema (e.g., set `PGRST_DB_SCHEMAS="apflora"` and a valid anon role).
2) Make a request such as `GET /`.
3) The client may receive a connection failure (e.g., “Empty reply from server” / connection error).

Actual behavior:
- No corresponding error line is emitted to PostgREST logs when the underlying failure is an async exception like `StackOverflow`.

Expected behavior:
- When the Warp server hits an exception that terminates request handling and drops the connection, PostgREST should emit a log line that includes Warp’s error prefix and the exception message.
- In particular, a stack overflow must be logged as:
  
  `Warp server error: stack overflow`

Constraints/behavioral details:
- Warp’s default exception display logic suppresses asynchronous exceptions (via `isAsyncException`), but PostgREST should not hide these, since they can indicate serious faults.
- At the same time, PostgREST should still avoid log flooding by continuing to ignore exceptions that are considered safe/expected under normal server operation (e.g., common client disconnect scenarios), while ensuring genuinely important async exceptions (like `StackOverflow`) are logged.

Verification scenario:
- Under the large-schema setup where `GET /` triggers a stack overflow and the client experiences a connection error, PostgREST’s stdout/stderr logs must contain at least one line with the substring `Warp server error: stack overflow`.