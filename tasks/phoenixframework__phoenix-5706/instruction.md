Generating a new Phoenix application should default to using Bandit as the web server adapter, while still supporting Cowboy as a first-class option and preserving backwards compatibility when an adapter is explicitly selected.

Currently, when running the Phoenix installer to generate a new project (including umbrella projects), the generated files and dependency/configuration output are not consistently aligned with the intended default adapter behavior. The generator should:

1) Use Bandit by default for newly generated Phoenix apps when no adapter is specified.

2) Continue to support Cowboy as an explicitly selectable adapter. If the user explicitly chooses Cowboy (via generator options), the generated project must use Cowboy in its dependencies and endpoint configuration.

3) Preserve backwards compatibility: if an adapter is explicitly specified, do not change it implicitly. In other words, “default to Bandit” applies only when the adapter is not provided by the user.

4) Apply the same adapter-selection behavior to both standard project generation and umbrella project generation, so that the generated endpoint and dependencies are consistent in either layout.

Expected behavior examples:

- When running `Mix.Tasks.Phx.New.run(["my_app"])`, the generated `mix.exs` dependencies and endpoint/server configuration should be set up to run with Bandit.

- When running `Mix.Tasks.Phx.New.run(["my_app", "--adapter", "cowboy"])` (or the equivalent supported option for selecting an adapter), the generated output should instead include Cowboy and configure the endpoint accordingly.

- When generating an umbrella app with `Mix.Tasks.Phx.New.run(["my_app", "--umbrella"])`, the web child app’s dependencies and endpoint/server configuration should also default to Bandit unless Cowboy is explicitly selected.

The change should be reflected in the generated project’s configuration (including runtime configuration where the HTTP server is started/controlled), and in the generated dependency list, so that the project can compile and start its endpoint without requiring manual edits after generation.