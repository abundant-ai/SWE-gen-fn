UUIDv7 generation in `Ecto.UUID.generate/1` needs to support strictly time-ordered UUIDs under high throughput, and allow higher-than-millisecond clock precision, while keeping UUIDv4 behavior unchanged.

Currently, calling `Ecto.UUID.generate/1` only reliably supports default UUIDv4 generation and basic UUIDv7 generation, but it does not provide a way to guarantee strict monotonicity when multiple UUIDv7 values are generated within the same timestamp, and it does not support encoding sub-millisecond precision for UUIDv7.

Update `Ecto.UUID.generate/1` to accept new options in addition to the existing `:version` option:

- `monotonic: true | false` (default `false`): When `version: 7` and `monotonic: true`, UUID generation must be strictly monotonically increasing even if multiple UUIDs are generated within the same millisecond. In other words, if `uuid1 = Ecto.UUID.generate(version: 7, monotonic: true)` and immediately after `uuid2 = Ecto.UUID.generate(version: 7, monotonic: true)`, then `uuid1` must sort lexicographically before `uuid2`.

- `precision: :millisecond | :nanosecond` (default `:millisecond`): When `version: 7` and `precision: :nanosecond`, UUIDv7 generation must encode sub-millisecond precision such that multiple UUIDs within the same millisecond remain time-sortable with reduced timestamp drift under load. The produced UUID must still be a valid UUIDv7 string.

Validation rules must be enforced:

- If `:precision` or `:monotonic` is provided for UUIDv4 generation (either by default `generate()` or explicitly with `version: 4`), `Ecto.UUID.generate/1` must raise `ArgumentError`.

- `Ecto.UUID.generate()` with no options must continue to return a valid UUIDv4.

- `Ecto.UUID.generate(version: 7)` must continue to return a valid UUIDv7 that preserves time-based sortability across different milliseconds (a UUID generated after a measurable delay must sort after an earlier one).

Additionally, UUIDv7 monotonic and/or higher-precision generation requires any necessary runtime initialization to be performed when the Ecto application starts (via `Ecto.Application.start/2`), so that concurrent UUID generation remains safe and consistent.

The end result should be that UUIDv7 generation supports both:

- time-sortable UUIDs across milliseconds (default behavior),
- strictly monotonic ordering within the same timestamp when requested,
- optional nanosecond-derived precision when requested,

while rejecting unsupported option combinations for UUIDv4.