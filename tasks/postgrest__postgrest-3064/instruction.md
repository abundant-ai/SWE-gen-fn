PostgREST currently enables the HTTP `Server-Timing` response header when the `db-plan-enabled` configuration is turned on. This is incorrect because exposing an execution plan and emitting the `Server-Timing` header are independent concerns.

Introduce a new boolean configuration parameter named `server-timing-enabled` that exclusively controls whether PostgREST emits the `Server-Timing` header.

Expected behavior:
- When `server-timing-enabled = true`, PostgREST should include a `Server-Timing` header in responses (when timing metrics are available to report).
- When `server-timing-enabled = false` (the default), PostgREST must not include the `Server-Timing` header.
- Toggling `db-plan-enabled` must not, by itself, cause `Server-Timing` to appear or disappear. In particular:
  - `db-plan-enabled = true` with `server-timing-enabled = false` must not emit `Server-Timing`.
  - `db-plan-enabled = false` with `server-timing-enabled = true` must still be able to emit `Server-Timing`.

Configuration requirements:
- `server-timing-enabled` must be recognized as a standard boolean config option, appear in the normalized/printed configuration output, and have a default value of `false`.
- It must support the same boolean parsing behavior as other boolean options (e.g., accepting typical true/false encodings that PostgREST already supports for booleans).

The bug is considered fixed when `Server-Timing` is no longer implicitly tied to `db-plan-enabled` and is instead controlled solely by `server-timing-enabled`, with the default behavior being that `Server-Timing` is disabled unless explicitly enabled.