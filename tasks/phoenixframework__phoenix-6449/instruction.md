When generating a new Phoenix project with `Mix.Tasks.Phx.New.run/1` (the `phx.new` installer), the default configuration for the endpoint HTTP port in development is currently tied to build-time config (for example, it relies on environment lookups in a file intended for static compile-time configuration). This causes problems during upgrades and deployments because the `PORT` environment variable is a runtime concern and may differ between build and execution environments.

Update the generated project so that support for the `PORT` environment variable is handled in `runtime.exs` (runtime configuration) instead of in development build-time configuration. After generating a project with default options, the produced `config/runtime.exs` must configure the endpoint `http` port using the `PORT` environment variable with a default of 4000, converting it to an integer.

Specifically, the generated runtime configuration should include an endpoint HTTP setting equivalent to:

```elixir
http: [port: String.to_integer(System.get_env("PORT", "4000"))]
```

The generated runtime configuration should also continue to set the endpoint `ip` to the IPv6-any tuple `{0, 0, 0, 0, 0, 0, 0, 0}`.

Expected behavior: a freshly generated application reads `PORT` at runtime (when the release/node boots) and uses 4000 when `PORT` is not set.

Actual behavior to fix: the generated application relies on build-time config for `PORT`, so changing `PORT` at runtime is not reflected or the generated config is placed in the wrong config file for runtime evaluation.