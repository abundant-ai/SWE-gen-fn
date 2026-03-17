Generating a Phoenix project from an unreleased version can fail during `mix phx.new <app> --dev` because the installer expects a `core_components.ex` template to exist in the installer’s web component templates, but that file is missing in some unreleased/main setups.

Reproduction: follow the documented workflow for generating a Phoenix project from an unreleased Phoenix checkout, then run `mix phx.new dev_app --dev` from the installer context. The generation fails with a compilation error similar to:

```
== Compilation error in file lib/phx_new/web.ex ==
** (File.Error) could not read file ".../installer/templates/phx_web/components/core_components.ex": no such file or directory
```

Expected behavior: `mix phx.new ... --dev` should successfully generate an application without requiring any manual copying of template files. The generator should always be able to obtain `core_components.ex` and proceed even when working off an unreleased Phoenix checkout.

Required behavior:
- Ensure the installer/template set used by `mix phx.new` includes `core_components.ex` so project generation does not crash with `File.Error`.
- Ensure `core_components.ex` content used by the installer stays in sync with the canonical `core_components.ex` used by LiveView generation (the two sources should match byte-for-byte), so generated apps and live generators don’t drift.

After the fix, running `mix phx.new <app> --dev` should no longer raise a missing-file `File.Error`, and the core components template available to the installer should match the canonical core components template used elsewhere in Phoenix’s generators.