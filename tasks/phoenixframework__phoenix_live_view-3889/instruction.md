Running `mix phoenix_live_view.upgrade 1.0.0 1.1.0` should apply a repeatable (idempotent) set of project changes required to upgrade an application from Phoenix LiveView 1.0.x to 1.1.x, but the upgrader behavior is currently missing/incomplete.

Implement the upgrade so that invoking the upgrade command performs these changes:

When the project’s `mix.exs` does not yet include the `:lazy_html` dependency, the upgrader must add `{:lazy_html, ">= 0.0.0", only: :test}` to the dependency list. If `mix.exs` already has a `:phoenix_live_view` dependency (for example `{:phoenix_live_view, "~> 0.20.0"}`), the upgrader must still add `:lazy_html` appropriately without breaking the dependency list formatting.

The upgrader must also ensure the project compilers include the LiveView compiler. If the `project/0` configuration in `mix.exs` does not specify `compilers:`, the upgrader should add `compilers: [:phoenix_live_view] ++ Mix.compilers()` alongside the existing project keys (and preserve valid Elixir syntax, including commas between keys). If `compilers:` is already configured exactly as `[:phoenix_live_view] ++ Mix.compilers()`, the upgrader must make no changes and must not emit warnings.

If `compilers:` is configured in a non-trivial way (for example `compilers: custom_compilers()` or otherwise not a direct list concatenation that the upgrader can safely modify), the upgrader must not attempt an unsafe rewrite; instead it should leave the file unchanged and emit a warning indicating that compiler configuration could not be automatically updated and needs manual attention.

Finally, the entire upgrade must be idempotent: running `mix phoenix_live_view.upgrade 1.0.0 1.1.0` multiple times on the same project should produce no additional changes after the first successful application (no duplicated dependencies, no duplicated compiler entries, and no repeated edits).