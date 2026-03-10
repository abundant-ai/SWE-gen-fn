PostgREST currently has no request-level way to change the database timezone for how timestamp/date values are interpreted and rendered, other than creating roles with a preset timezone (e.g., `alter role ... set time zone 'America/Los_Angeles'`). This makes it difficult to serve clients in different timezones without extra DB roles.

Add support for a client-specified timezone via the `Prefer` request header using the form `Prefer: timezone=America/Los_Angeles`.

When a request includes a timezone preference, PostgREST must apply it for the duration of that request only by setting the PostgreSQL session’s timezone locally (equivalent to running `set local time zone '<tz>'` inside the request transaction) so that all SQL in that request uses that timezone.

The timezone preference must be reflected back to the client in the `Preference-Applied` response header (i.e., include the timezone preference that was applied).

Invalid timezone values must be rejected. If the client supplies a timezone that PostgreSQL does not accept, the request must fail with `406 Not Acceptable` (rather than silently ignoring it or returning a 400/500). This should work consistently across request types (reads, writes, and RPC calls).

The preference parsing must also interact correctly with existing `Prefer: handling=strict` vs `Prefer: handling=lenient` behavior: unknown/invalid preferences are handled according to that existing mechanism, but an explicitly provided `timezone=...` that is syntactically valid as a preference yet not applicable/accepted by PostgreSQL must result in `406 Not Acceptable`.

Example behavior:

- `GET /items` with `Prefer: timezone=America/Los_Angeles` should run the request under that timezone and respond successfully, including `Preference-Applied: timezone=America/Los_Angeles`.
- `GET /items` with `Prefer: timezone=Not/A_Timezone` must respond with HTTP 406.

Implement this in a way that applies per-request and does not leak the timezone setting across concurrent requests or pooled connections.