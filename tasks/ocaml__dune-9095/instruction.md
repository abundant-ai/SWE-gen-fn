A new command is needed to inspect a project’s lockdir and report which dependencies of local packages are locked, including which ones are only present when tests are enabled.

Implement `dune describe pkg list-locked-dependencies` so that, when run in a project with a `dune.lock`, it prints the locked dependencies of each local package in a stable, human-readable form. By default it must list only the immediate locked dependencies (those corresponding to the package’s declared dependencies), and it must annotate dependencies that are only brought in via `:with-test` as ` (test only)`.

The command must also support `--transitive`, in which case it lists the transitive closure of locked dependencies for each local package. In transitive mode, only immediate test-only dependencies of the local package (and their normal transitive dependencies) should be included as test-only; it must not recursively treat “test-only dependencies of test-only dependencies” as test-only for annotation/selection purposes.

The output must include a header `Dependencies of local packages locked in dune.lock` and then, for each local package, a section titled either `Immediate dependencies of local package <name>.dev` or `Transitive dependencies of local package <name>.dev`, followed by one dependency per line. Local packages should be referenced as `<pkg>.dev`, while locked opam packages should be printed as `<name>.<version>`.

Error handling is required for conditional dependencies that cannot be validated against the lockdir produced by the solver (which runs with `with_test=true`).

1) If a local package has a dependency that is only required when `:with-test` is false (e.g. `(foo (= :with-test false))`), the lockdir will not contain that dependency. In this case `dune describe pkg list-locked-dependencies` must fail with an error of the form:

`Error: Unable to find dependencies of package "<local_pkg>" in lockdir when the solver variable 'with_test' is set to 'false':`
followed by a line describing the missing package, e.g. `Package "foo" is missing`.

2) If a local package specifies different version constraints depending on `:with-test` (e.g. `(a (or (= 0.0.1) (and :with-test (= 0.0.2))))`), the lockdir will only contain the version compatible with `with_test=true`. When validating dependencies for the `with_test=false` branch, the command must detect that the locked version is incompatible and fail with a clear error indicating that dependencies for `with_test=false` cannot be found due to an incompatible locked version (include the package name and make it clear it is a version/constraint mismatch, not just missing).

The command should work for projects with multiple local packages, where one local package depends on another local package, and should correctly show local-to-local edges as `<other>.dev` in immediate mode and include them in transitive mode as part of the dependency set.