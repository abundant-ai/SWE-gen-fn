Users need to be able to decide at build time whether to build test dependencies, rather than having the dependency solver decide this at solve/lock time based on solver environment flags. Currently, the solver environment includes opam-style flags like "with-test" and "with-doc", which causes the solve step to include/exclude dependencies based on these flags. This makes it impossible to generate a lockdir that always contains the local package’s test dependencies (so they can be enabled later at build time) while still avoiding pulling in test dependencies of transitive dependencies.

Change the behavior so that the solver environment no longer contains or exposes "with-test" and "with-doc" flags at all. When generating a lockdir, the solve should effectively behave as if "with-test" is enabled only for the local package being locked, ensuring that dependencies guarded by {with-test} for the local package are included in the lockdir solution. At the same time, documentation-only dependencies should not be included in the lockdir solution (there is no use case for locking doc-only dependencies), so "with-doc" should be treated as always disabled for solving/locking.

This should also be reflected in the CLI output for printing the solver environment: running `dune pkg print-solver-env` (including `--all-contexts`) should not show any "with-test" or "with-doc" entries as part of the solver environment for any context.

Expected behavior examples:
- When solving/locking a local package that has dependencies filtered by {with-test}, those dependencies should appear in the resulting lock solution.
- Documentation-only dependencies filtered by {with-doc} should be omitted from the solution.
- Printing the solver environment should only include system variables, constants like the opam version, and repositories; it must not include solver flags for tests/docs.

Actual behavior to fix: the solver environment still contains "with-test"/"with-doc" and the solve result depends on them, preventing lockdir generation from consistently including local test dependencies while excluding doc-only dependencies.