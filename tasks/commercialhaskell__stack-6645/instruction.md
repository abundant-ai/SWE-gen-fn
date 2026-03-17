When running `stack build` with tests and/or benchmarks enabled but with `--no-run-tests` and/or `--no-run-benchmarks` in effect (either via CLI flags or equivalent configuration), Stack still plans test/benchmark actions and then “executes” them as no-ops. This causes misleading output like `Completed 4 action(s).` on a subsequent build even though nothing actually ran, because the listed actions correspond only to test suites/benchmarks that were skipped due to the no-run flags.

Reproduction example: configure a project so that builds enable tests and benchmarks, but pass no-run options, e.g.

```yaml
build:
  test: true
  test-arguments:
    no-run-tests: true
  bench: true
  benchmark-opts:
    no-run-benchmarks: true
notify-if-no-run-tests: false
notify-if-no-run-benchmarks: false
```

Then run `stack build` twice. On the second run, Stack should behave like a true no-op (no planned/claimed actions) if the only potential remaining actions would be running tests/benchmarks that are disabled by the no-run flags.

Current behavior:
- Stack still includes per-package test/benchmark actions in the action plan even when `runTests`/`runBenchmarks` are disabled by `--no-run-tests`/`--no-run-benchmarks`.
- This leads to output indicating completed actions (e.g. `Completed N action(s).`) even though tests/benchmarks are not run.
- With notifications enabled, Stack emits multiple per-package lines such as `packageA> Test running disabled by --no-run-tests flag.` and similar for benchmarks, and still reports completed actions.

Expected behavior:
- The no-run flags must be respected at the time the list of actions is created (planning), not only during execution.
- If `--no-run-tests` is in effect, Stack must not add test-running actions for packages/test-suites to the planned actions list.
- If `--no-run-benchmarks` is in effect, Stack must not add benchmark-running actions to the planned actions list.
- When notifications are enabled, Stack should emit a single global message indicating all test running and/or all benchmark running is disabled (including a hint that the message can be muted via `notify-if-no-run-tests: false` / `notify-if-no-run-benchmarks: false`), rather than emitting per-package messages.
- When notifications are disabled, the second `stack build` in the above scenario should produce no “completed action(s)” attributable solely to skipped tests/benchmarks (i.e., it should appear as a no-op).

The behavior must be consistent regardless of whether flags appear before or after the `build` command (e.g. both `stack --test --no-run-tests build` and `stack build --test --no-run-tests` should result in the global “All test running disabled by …” message when notifications are enabled).