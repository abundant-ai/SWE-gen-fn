Phoenix’s scoped generators currently use a scope configuration parameter named `:test_login_helper` to inject a `setup` callback into generated tests for resources created inside that scope (for example, generating tests that include something like `setup :register_and_log_in_user`). This name is misleading and tightly coupled to authentication, even though scopes are intended to be usable independently of `phx.gen.auth`.

When a developer defines a scope that is not related to authentication (for example, a `GeoRestriction` scope), the generators still expect a `:test_login_helper` config value to specify the setup callback to run for tests generated within that scope. This makes configuration confusing and semantically incorrect, because the test setup may not involve logging in at all.

Update the scoped generator configuration and all code generation paths so that scopes use a renamed, auth-agnostic configuration key: `:test_setup_helper`.

After this change:

- When a scope is configured with `test_setup_helper: :some_setup_fun`, resources generated within that scope must have generated tests that call the setup callback via `setup :some_setup_fun`.
- The generators must no longer rely on `:test_login_helper` as the primary key for this behavior.
- End-to-end generated applications that include scopes (for example, apps that run `phx.gen.auth` and then generate additional resources like LiveView/HTML/JSON within the created scope) must compile without warnings, pass formatting checks, and have their generated test suites pass using the new key.

If a developer is upgrading an app that previously used `:test_login_helper`, the generator behavior should not silently generate incorrect tests; either `:test_login_helper` should be treated as deprecated compatibility (mapping to the new behavior) or the failure mode should be clear and actionable when the old key is present and the new key is missing.

Example of the desired configuration semantics:

```elixir
# inside config/config.exs (or equivalent scope configuration)
config :my_app, :scopes,
  geo_restriction: [
    test_setup_helper: :create_geo_restriction
  ]
```

With this configuration, generating a resource within the `geo_restriction` scope should produce tests that include:

```elixir
setup :create_geo_restriction
```

and the generated project’s tests should run successfully.