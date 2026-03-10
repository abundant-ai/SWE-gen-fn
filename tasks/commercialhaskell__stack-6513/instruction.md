`stack haddock` currently lacks an equivalent to `cabal haddock --executables`/`--tests`/`--benchmarks`, so documentation for executable-only (and similarly test/benchmark-only) code cannot be generated via Stack. Projects with significant non-library code cannot produce Haddocks for those components using Stack’s Haddock command.

Add support for generating Haddock documentation for executables, test suites, and benchmarks via both configuration and command-line flags.

When configuring build options (eg in `stack.yaml` under `build:`), the following boolean keys should be recognized and affect Haddock generation:

- `haddock-executables: true`
- `haddock-tests: true`
- `haddock-benchmarks: true`

These settings must be loaded by `loadConfig`/`loadConfigYaml` into the build configuration and reflected in the resulting `BuildOpts`/`HaddockOpts` values used when running `stack haddock`.

Additionally, `stack haddock` should accept corresponding command-line flags `--haddock-tests` and `--haddock-benchmarks` (and continue to support `--haddock-executables`), such that enabling these flags causes Stack to request Haddock generation for the chosen component types. The flags should merge correctly with configuration: explicit CLI flags should enable the relevant behavior even if the config defaults are false.

Expected behavior:
- With `haddock-executables` enabled (config or CLI), `stack haddock` generates Haddocks for executables in the project.
- With `haddock-tests` enabled, `stack haddock` generates Haddocks for test suites.
- With `haddock-benchmarks` enabled, `stack haddock` generates Haddocks for benchmarks.
- The configuration parser should accept those keys without error, and the resulting options object (including fields in `HaddockOpts`) should reflect `True` when set.

Actual behavior to fix:
- Stack ignores or does not provide these options, so calling `stack haddock` cannot generate docs for executables/tests/benchmarks, and/or parsing a config containing `haddock-tests` / `haddock-benchmarks` does not populate the corresponding options.