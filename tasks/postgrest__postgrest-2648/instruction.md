PostgREST is returning inaccurate API error codes in at least two user-facing error scenarios. This breaks clients that rely on stable `code` values in the JSON error body.

1) When a request uses the `columns` parameter (or related functionality that restricts/targets specific columns) and a referenced column does not exist, PostgREST should return a JSON error response whose `code` matches the new, correct PostgREST error code for “column not found”. Currently, it returns an older/inaccurate code.

Reproduction example:
- Make a write request (e.g., INSERT/UPDATE/PATCH) that uses `columns` (or an equivalent mechanism that sets explicit target columns) and include at least one column name that does not exist on the target table.
- Actual behavior: the response contains a JSON error object with an incorrect `code` value.
- Expected behavior: the response should use the new “column not found when using columns” error code, while preserving the correct HTTP status and a meaningful `message`.

2) When PostgREST cannot acquire a database connection from the pool within the configured timeout, it should return a JSON error response whose `code` matches the new, correct PostgREST error code for “timeout acquiring connection from the DB pool”. Currently, it returns an older/inaccurate code.

Reproduction example:
- Configure a small pool / saturate connections so that new requests must wait.
- Trigger a request that requires a DB connection until the pool acquisition timeout occurs.
- Actual behavior: the response contains a JSON error object with an incorrect `code` value.
- Expected behavior: the response should use the new “db pool acquisition timeout” error code, with an appropriate HTTP status and error `message`.

In both cases, only the PostgREST-specific error code identifier in the JSON error body should change to the new correct value; the error should still be returned as a standard PostgREST error JSON object (including fields like `message`, `code`, `details`, `hint` where applicable).