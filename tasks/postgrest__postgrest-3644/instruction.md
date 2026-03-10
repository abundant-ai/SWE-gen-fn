When PostgREST starts up and loads the schema cache, failures during the schema cache query can cause the loader to retry in a tight loop without exponential backoff. This becomes easy to reproduce by setting a low statement timeout for the role used by PostgREST (for example, setting `statement_timeout` to 10ms for the authenticator role). With this setup, schema cache loading times out and PostgREST repeatedly prints log lines like `Attempting to connect to the database...` many times per second.

The schema cache load retry mechanism is expected to use exponential backoff between attempts. Instead, when the failure is caused by query timeouts/cancellation during schema cache loading, the retry delay is not applied (or is reset/ignored), leading to an endless rapid retry loop.

Fix the schema cache load retry behavior so that:

- If `querySchemaCache` fails during startup (including failures caused by `statement_timeout`, query cancellation, or other transient database errors), PostgREST retries the schema cache load with exponential backoff rather than immediately looping.
- The retry mechanism must not spin at 0 delay; each subsequent failure should increase the wait time up to the configured/expected maximum backoff.
- The log output should not flood with repeated instantaneous `Attempting to connect to the database...` messages under these failures; it should reflect the backoff behavior.
- Existing PostgreSQL error handling/mapping behavior should remain correct for request-time errors, including returning HTTP 500 for errors like `cardinality_violation` and returning HTTP 500 with the PostgreSQL error payload for errors such as stack depth limit exceeded (code `54001`).

The key functional requirement is that schema cache loading failures are treated as retryable with exponential backoff, even when the underlying connection exists but the schema cache query itself times out, so startup does not enter a busy loop.