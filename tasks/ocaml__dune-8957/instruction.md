`dune pkg outdated` (and related package/lockfile reporting commands) currently produces inconsistent and sometimes awkward vertical spacing because it relies on `Pp.newline` to force blank lines/newlines in places where the output should instead be structured as a vertically formatted block.

When running `dune pkg outdated`, the output should be uniformly formatted using vertical composition (a vbox-style layout) rather than inserting raw newlines. This should result in consistent indentation and spacing across:

- The “up to date” cases (single lockfile and `--all-contexts` where multiple lockfiles are reported).
- The “outdated packages found” cases (including counts like `1/2 packages in dune.lock are outdated.` and listing lines like `- bar 0.0.1 < 0.0.2`).
- The “immediate dependencies only” message shown when transitive outdated packages exist but `--transitive` is not passed (e.g., `Showing immediate dependencies, use --transitive to see them all.`).
- Mixed success + error output where some outdated packages can be reported but there are also missing packages in the repository. In these cases, any error messages must appear after the successful outdated-package summary, separated cleanly without relying on ad-hoc blank lines.

Additionally, the solver output used by package locking commands must remain stable and readable, including scenarios where the opam repository contains dependency cycles: the solver should still print a coherent “Solution for dune.lock:” (or workspace lock) followed by a stable list of selected packages and versions.

The key problem to fix is that output formatting should stop using `Pp.newline` as a way to create vertical spacing; instead, the output must be composed so that spacing is a natural result of vertical layout. After this change, `dune pkg outdated` output should be more uniform and should not depend on special-casing to avoid extra blank lines or mis-indentation in different modes (`--all-contexts`, `--transitive`, and error cases).