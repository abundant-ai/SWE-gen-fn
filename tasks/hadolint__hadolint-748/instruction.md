Hadolint currently supports “inline ignore pragmas” in Dockerfiles, e.g. a comment like `# hadolint ignore=DL3003`, which suppresses the specified rule(s) for the relevant instruction. In some environments (notably centralized CI), it should be possible to forbid these inline bypasses so that all rules are still applied even if developers add ignore pragmas.

Implement a configuration option that disables interpretation of inline ignore pragmas.

When the option is enabled, hadolint must behave as if inline ignore pragmas do not exist: rules referenced by `# hadolint ignore=DLxxxx` must still be evaluated and reported normally. The option must be configurable via:

- Command line flag `--disable-ignore-pragma`
- Environment variable `HADOLINT_DISABLE_IGNORE_PRAGMA=1` (and be able to parse falsy values such as `0`)
- Configuration file key `disable-ignore-pragma: true`

This option must also participate correctly in configuration merging: applying a partial configuration containing `disable-ignore-pragma=true` over the default configuration should result in a final configuration where `disableIgnorePragma` is set to `True`.

Additionally, add a new rule with code `DL1001` that detects the presence of an inline ignore pragma and reports it (message: “Please don't use inline ignore pragma.”). The rule should trigger on lines containing an inline ignore pragma of the form `# hadolint ignore=...` and must not trigger for other pragmas (e.g. `# hadolint shell=powershell`), other comments, or Dockerfiles that contain no inline ignore pragma.

By default, `DL1001` should not fail builds unless the user explicitly enables it by setting its severity (for example, configuring `DL1001` as a warning). When enabled, it should emit a finding whenever an inline ignore pragma is present, regardless of whether ignore pragmas are being honored or disabled.

Example scenario that must work:

- Given a Dockerfile containing:
  ```
  # hadolint ignore=DL3003
  RUN foo bar
  ```
  - If `--disable-ignore-pragma` is enabled, `DL3003` must still be reported if it would normally be reported.
  - If `DL1001` is enabled at warning (or higher), it must report `DL1001` for the presence of the inline ignore pragma.