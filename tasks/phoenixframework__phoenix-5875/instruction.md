Phoenix endpoints currently treat the `:watchers` configuration as a keyword list and do not allow it to be overridden/disabled when configuration is merged/overridden (for example via runtime config overrides). This makes it impossible to explicitly turn watchers off in an overriding config, because keyword-based config merging won’t replace the existing value.

Update the endpoint supervision/configuration logic so that setting `watchers: false` is treated as an explicit “disable watchers” directive.

When an endpoint’s configuration resolves to `watchers: false`, the endpoint supervision startup should behave as if there are no watchers configured: it must not attempt to start any watcher-related processes and must not require `:watchers` to be a keyword list.

Expected behavior:
- `Phoenix.Endpoint.Supervisor.config/2` should allow `:watchers` to be either a keyword list (existing behavior) or the boolean `false`.
- If `:watchers` is `false`, watcher child specs are not added/started.
- If `:watchers` is a keyword list, existing behavior remains unchanged.

Actual behavior to fix:
- Providing `watchers: false` in endpoint config either fails to override an existing watchers keyword configuration or causes watcher handling code to treat `false` as an enumerable/keyword list, leading to errors or unintended watcher startup.
