Phoenix’s project generators are not compatible with the updated Gettext API introduced in newer versions of Gettext. When generating a new Phoenix project (including umbrella projects) with `Mix.Tasks.Phx.New.run/1`, the produced code should use the new Gettext API conventions and compile/work correctly, but currently the generated files still assume the older API and end up producing incorrect Gettext module usage in generated applications.

Fix the Phoenix generators so that newly generated apps use the new Gettext API end-to-end. In particular:

- Generating a new project with defaults via `Mix.Tasks.Phx.New.run([app_name])` must create a project whose generated configuration and modules match current Phoenix conventions and do not reference outdated Gettext APIs.
- Generating a new umbrella project via `Mix.Tasks.Phx.New.run([app_name, "--umbrella"])` must likewise generate correct Gettext-related code across the umbrella root and the web/app children.
- Ensure that all generator templates that emit Gettext usage (for example, the generated `Gettext` module, imports/aliases in web modules, and any translated strings usage in controllers/live/components/templates) are updated to the new API so the generated project builds cleanly against current Gettext.

After the change, a freshly generated project should have consistent, up-to-date generated files (including the expected formatter and config defaults) and should not emit any legacy Gettext calls or module definitions that are incompatible with the new Gettext releases referenced in the PR description.