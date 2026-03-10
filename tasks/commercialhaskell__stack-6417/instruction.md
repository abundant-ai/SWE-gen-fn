The Stack configuration/options type for Nix integration, `NixOpts`, has record field names that include a `nix` prefix (for example fields like `nixEnable`, `nixPackages`, etc.). These prefixed names should be removed so that the record uses unprefixed field names (for example `enable`, `packages`, and any other Nix option fields), while keeping behavior identical.

After this change, all code paths that construct, parse, or consume `NixOpts` must still work:

- Loading a `stack.yaml` containing a `nix:` section must populate `Config.nix.enable` correctly. For example, with:
  ```yaml
  nix:
    enable: true
    packages: [glpk]
  ```
  `config.nix.enable` must be `True`, and disabling it via:
  ```yaml
  nix:
    enable: false
  ```
  must result in `config.nix.enable == False`.

- Command-line parsing for Nix options must still produce a valid `NixOpts` value via `nixOptsParser`, and downstream code (including `nixCompiler` and config loading via `loadConfig`) must access the renamed fields correctly.

Currently, after removing the prefixes on `NixOpts` fields in one place, other modules still refer to the old prefixed field names, causing compilation errors and/or incorrect behavior when reading `Config.nix.enable` and other Nix settings. Update all references so the project builds and the Nix enable/disable behavior remains correct across both config-file and CLI paths.