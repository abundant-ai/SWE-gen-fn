When PostgREST receives certain PostgreSQL errors in the SQLSTATE class `54xxx` (program limit exceeded), it currently maps them to HTTP `413 Request Entity Too Large`, which is a client-side error and misleading for server-side failures such as runaway recursion.

A concrete example is an insert that triggers infinite recursion (e.g., an AFTER INSERT trigger that inserts into the same table again). Posting a normal-sized JSON payload like:

```http
POST /infinite_inserts
Content-Type: application/json

{"id": 3, "name": "qwer"}
```

can cause PostgreSQL to fail with SQLSTATE `54001` and message `stack depth limit exceeded` (with a hint about increasing `max_stack_depth`). PostgREST currently responds with HTTP status `413` while returning the PostgreSQL error body, e.g.:

```json
{
  "code": "54001",
  "details": null,
  "hint": "Increase the configuration parameter \"max_stack_depth\" (currently 2048kB), after ensuring the platform's stack depth limit is adequate.",
  "message": "stack depth limit exceeded"
}
```

This status code is incorrect: the request entity is not too large; the failure is due to server-side execution limits / program complexity.

Update the PostgreSQL error-to-HTTP mapping so that SQLSTATE `54xxx` errors (including `54001`) return HTTP `500 Internal Server Error` instead of `413`. The JSON error payload (code/message/hint/details) should still be returned; only the HTTP status mapping should change. As a sanity check, a request that triggers `statement too complex` / `stack depth limit exceeded` with code `54001` must respond with status `500`.