Generating a new Phoenix project currently sets up Swoosh to use Finch as the default HTTP client. This requires the generated application to start Finch in the supervision tree and include Finch-specific configuration, even though Swoosh supports using Req as an HTTP client. The installer should default to Req (Req v1.0+) instead of Finch so that newly generated projects don’t need to manually supervise an HTTP client process.

When running `Mix.Tasks.Phx.New.run([app_name])` with default options, the generated project should:

- Configure Swoosh to use `Swoosh.ApiClient.Req` as the API client rather than Finch.
- Not add Finch to the application’s supervision tree (no `Finch` child spec should be generated in the application module).
- Not generate Finch-specific configuration for Swoosh.

The same behavior should apply when generating an umbrella project via `Mix.Tasks.Phx.New.run([app_name, "--umbrella"])`: the generated apps should use Req as the default Swoosh client and should not include any Finch supervision/config boilerplate.

After these changes, the installer output should remain consistent and the generated files should match the expected templates for both regular and umbrella projects when using defaults.