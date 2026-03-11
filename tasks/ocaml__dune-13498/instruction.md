The `dune pkg enabled` command does not correctly reflect package-management enablement when `--ignore-lock-dir` is used. This command is intended to be a pure check: it should exit successfully (code 0) when package management is enabled, and exit with code 1 when it is disabled.

Currently, with a lock directory present, `dune pkg enabled` exits successfully as expected. However, running `dune pkg enabled --ignore-lock-dir` incorrectly reports package management as enabled (exit code 0) even though `--ignore-lock-dir` is intended to disable package management in this context. Users expect:

- If no lock directory exists, `dune pkg enabled` should exit with code 1 by default.
- If a lock directory exists, `dune pkg enabled` should exit with code 0 by default.
- `--pkg enabled` should force the check to succeed (exit code 0) regardless of workspace configuration.
- `--pkg disabled` should force the check to fail (exit code 1) regardless of workspace configuration.
- If `-p <pkg>` is provided, it should imply `--pkg=disabled`, causing `dune pkg enabled` to exit with code 1 even if the workspace would otherwise enable pkg.
- The legacy `--ignore-lock-dir` flag should no longer exist. Invocations using it should not affect enablement checks; instead, the codebase should rely on the `--pkg` flag modes to express behavior. In particular, there should be no situation where `dune pkg enabled --ignore-lock-dir` is accepted and returns success when the intent is to disable package management.

Fix the CLI and enablement logic so that enablement checks are consistent and unambiguous with respect to `--pkg` and `-p`, and so that `--ignore-lock-dir` is removed from the interface and cannot produce the incorrect enablement result described above.