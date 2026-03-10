PostgREST currently logs schema cache timing details at normal log levels after schema cache load. In particular, it emits lines like:

```
Schema cache queried in 16.3 milliseconds
Schema cache loaded 264 Relations, 221 Relationships, 142 Functions, 15 Domain Representations, 45 Media Type Handlers
Schema cache loaded in 16.7 milliseconds
```

The final line ("Schema cache loaded in <x> milliseconds") is intended for debugging only: users generally cannot take action to reduce that time, so it should not appear when running with the default/normal log verbosity.

Change the logging behavior so that the "Schema cache loaded in <x> milliseconds" message is only emitted when the configured log level is `debug` (for example when running with `log-level=debug` / `PGRST_LOG_LEVEL=debug`). When the log level is `info` (or other non-debug levels), PostgREST should still be able to start normally and may keep other schema cache log lines as they are today, but it must not print the total schema cache load time line.

Expected behavior:
- With `log-level=debug`, all three schema cache lines above can be present, including the total load time line.
- With `log-level=info` (and other non-debug levels), the total load time line must be suppressed (not printed), while the rest of PostgREST behavior remains unchanged.

Actual behavior:
- The total load time line is printed even when not running at debug log level.