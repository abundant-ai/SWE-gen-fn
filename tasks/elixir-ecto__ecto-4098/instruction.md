`Ecto.Query.from/2` and the `join` keyword options do not currently accept interpolated values for the `:prefix` option. When a developer tries to override a schema’s `@schema_prefix` dynamically by writing an interpolated prefix, query construction fails because `:prefix` is treated as requiring a compile-time literal.

Repro:

```elixir
import Ecto.Query

prefix = "hello"
from(c in "comments", prefix: ^prefix)
```

Expected behavior: building the query should succeed, and the query’s source (and join sources, when `join: ...` is used with `prefix:`) should use the runtime value of `prefix` as the prefix. This should work both for `from/2` sources and for joins that specify a `:prefix` option.

Actual behavior: using `prefix: ^prefix` in `from/2` (and similarly in join options) is rejected during query compilation/building, because interpolated values are not supported for `:prefix`.

Implement support for interpolated `:prefix` values in both `from` and `join` options so that callers can dynamically set the prefix at runtime via `^value` without raising an error, while preserving existing behavior for literal prefixes.