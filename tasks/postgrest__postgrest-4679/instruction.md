Startup schema-cache logging currently emits redundant observation events for the same schema-load operation: one event for a summary and another for the timing (“SchemaCacheSummaryObs” and “SchemaCacheLoadedObs”). This coupling between observation events and log formatting causes duplicate/overlapping log entries and makes it difficult to emit zero, one, or multiple log messages for a single observation.

The observation/logging layer should be refactored so that schema cache loading emits a single observation event that contains both the summary text and the timing information, and the logging layer can decide how many log lines to emit for that one event.

Concretely:

- The observation message formatter currently behaves like a function similar to `observationMessage :: Observation -> Text` (one observation maps to exactly one log line). Change this interface so that an observation can produce multiple (or zero) log messages, e.g. `observationMessages :: Observation -> [Text]`, and update all callers accordingly so logging still works.
- Remove the redundant `SchemaCacheSummaryObs` constructor from the `Observation` type.
- Extend/adjust `SchemaCacheLoadedObs` so it carries the schema cache summary text in addition to the load duration/timing data. When schema loading completes, emit only this single observation event rather than two separate ones.

Expected behavior visible to users:

- PostgREST startup logs must still include a line that matches the format `Schema cache loaded in <N> milliseconds` where `<N>` is a numeric duration (integer or decimal). This log line should appear exactly once per schema cache load and be parseable with a regex like `Schema cache loaded in ([0-9]+(?:\.[0-9])?) milliseconds`.
- The duration value must represent the actual schema cache load elapsed time (not zero, not missing). In environments with a large schema, this duration should be a realistic non-trivial value (e.g., > 100ms) and should not exceed a configured maximum in such scenarios.
- No additional redundant schema-cache “summary” observation should be emitted separately; the summary should be carried by the single schema-loaded observation, and any summary logging should be derived from that one event.

The change should preserve existing logging behavior for other observation events while allowing an observation to emit multiple log lines when appropriate (e.g., when an event naturally has more than one message).