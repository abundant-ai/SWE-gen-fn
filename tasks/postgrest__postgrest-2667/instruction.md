When PostgREST reaches the configured timeout for acquiring a database connection (controlled by `db-pool-acquisition-timeout`), it raises an `AcquisitionTimeoutUsageError`. Currently, this condition does not emit an error message to stderr, which makes it difficult for administrators to diagnose that the connection pool is saturated (pool too small) or that queries are holding connections too long.

Update PostgREST so that when an `AcquisitionTimeoutUsageError` occurs, an error is logged to stderr. The message should clearly indicate that acquiring a connection from the pool timed out and should point to `db-pool-acquisition-timeout` as the relevant setting.

Because this timeout can be triggered by many concurrent requests, the stderr logging must be debounced: repeated `AcquisitionTimeoutUsageError` occurrences in a short period should not spam stderr. After a burst, only a limited number of messages should be emitted (e.g., one per debounce window), while still ensuring that at least one error is logged when the problem first appears.

Expected behavior:
- With `db-pool-acquisition-timeout` set and the pool exhausted such that a request cannot acquire a connection before the timeout, PostgREST emits an error to stderr mentioning the acquisition timeout and the configuration key.
- Under sustained load where many requests hit the same acquisition timeout, stderr output remains bounded due to debouncing (it should not log once per request).

Actual behavior:
- Requests can fail due to acquisition timeout without any corresponding stderr error log, leaving admins without a clear signal of pool exhaustion/timeouts.