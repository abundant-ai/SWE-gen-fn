Hadolint’s “failure threshold” behavior is incorrect and inconsistent with the documented semantics.

Hadolint should only exit with a non-zero status when at least one violated rule has a severity strictly above the configured threshold (exclusive comparison). Currently, threshold handling is treated as inclusive in some cases (violations at the threshold severity cause a failure), and there are also cases where setting the threshold to the highest severity (e.g., `error`) incorrectly results in exit code 0 even when `error`-severity violations exist.

Reproduction examples:

1) Exclusive threshold semantics
- Run hadolint with a threshold of `info` on a Dockerfile that produces only `info` violations (and nothing more severe).
- Expected: exit code 0, because there are no violations above `info`.
- Actual: exit code 1 (hadolint treats `info` as inclusive and fails on `info` violations).

2) Threshold at `error` should still fail on errors
- Run hadolint with `--failure-threshold error` on a Dockerfile that produces one or more `error`-severity violations.
- Expected: exit code 1.
- Actual: exit code 0.

Additionally, the PR introduces a new CLI option `--threshold` (short `-t`) that configures the severity threshold. Supported values must include `error`, `warning`, `info`, `style`, `ignore`, and `none`.

Required behavior for thresholds:
- Default threshold is `info`.
- Hadolint must exit with failure only when at least one violation has severity strictly greater than the configured threshold.
  - Example: threshold `warning` should ignore `style` and `info` violations (exit 0 if those are the only violations) but should fail (exit 1) if any `error` violations are present.
- `ignore` and `none` must both behave as “fail if any rule is violated” (i.e., any violation of any severity causes exit code 1).
- A threshold of `error` must have the same effect as disabling failures altogether (equivalent to `--no-fail`): exit 0 regardless of violations.

Configuration parsing must continue to support severity-grouped overrides (e.g., per-severity lists like `override: error: [...]`, `override: warning: [...]`, `override: info: [...]`, `override: style: [...]`) without breaking existing config formats.

Fix the threshold logic so that exit codes are consistent with the above rules and the documented “above THRESHOLD” semantics, and ensure the new `--threshold/-t` option is correctly wired into the same behavior as existing threshold configuration.