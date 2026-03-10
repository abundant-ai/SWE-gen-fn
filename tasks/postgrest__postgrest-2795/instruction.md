PostgREST no longer recognizes the legacy configuration key `db-pool-timeout` (removed in v10.1.0). This removal didn’t cause a startup error, but it silently changed behavior: users who still set `db-pool-timeout` now get the default value for the pool idle timeout instead of their configured value.

The configuration system should treat `db-pool-timeout` as a backward-compatible alias for `db-pool-max-idletime`. When a user provides `db-pool-timeout = <N>`, the effective configuration must behave as if `db-pool-max-idletime = <N>` was set.

Reproduction example (simplified):

```ini
# legacy config
db-pool-timeout = 5
```

Expected behavior:
- The resulting effective configuration uses `db-pool-max-idletime` value of `5`.
- Any normalized/printed/inspected effective config output should reflect `db-pool-max-idletime = 5` (not `db-pool-timeout`).
- The alias should not cause an “unknown configuration key” warning/error.

Actual behavior:
- `db-pool-timeout` is ignored, so `db-pool-max-idletime` remains at its default value, changing connection pool behavior compared to pre-v10.1.0.

Implement support for this alias so that existing deployments using `db-pool-timeout` regain the prior behavior without needing to update their configuration files.