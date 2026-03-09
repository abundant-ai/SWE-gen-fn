When building packages with Dune’s package feature, the environment used for running `(build (system ...))` commands incorrectly handles `PATH` when dependencies are present.

Currently, if a package has no dependencies, system executables from the user environment (for example `cat`) can be found as expected during `(system ...)` steps. But if the same package adds `(deps ...)`, the package environment setup modifies `PATH` in a way that can drop or hide the user’s original `PATH` entries. As a result, common system tools are no longer found, and shell checks like `command -v cat` fail (e.g., it prints `no cat` or the command fails depending on the shell script).

The expected behavior is that `PATH` used in package builds is a merge of:
1) the package-provided `PATH` (so binaries produced by/installed from packages are found, e.g. a package’s `.../bin` directory), and
2) the user’s original `PATH` (so system executables like `cat`, `sh`, etc. remain available).

This merged behavior must be consistent whether or not `(deps ...)` is specified: adding dependencies must not change whether system executables are discoverable.

Additionally, packages automatically export certain environment variables (including `MANPATH`, `OCAMLPATH`, `CAML_LD_LIBRARY_PATH`, `OCAMLTOP_INCLUDE_PATH`, and `PATH`). These exported variables should continue to be set by the package environment, but for `PATH` specifically, the final value must preserve the user `PATH` while also prepending the package’s `bin` directory. For example, in a minimal environment where the user sets `PATH` to a custom directory containing only a few tools, the resulting `PATH` seen by `(system ...)` should start with the package’s `.../bin` directory and then include the user-provided `PATH` afterward (rather than replacing it).

Fix the package environment composition logic so that `PATH` is merged correctly between user and package environments, ensuring system commands remain available even when package dependencies are added, while still allowing package binaries to be found.