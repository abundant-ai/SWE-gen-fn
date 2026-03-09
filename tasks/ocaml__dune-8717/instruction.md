When a build rule declares a dependency using `(deps (package <name>))`, Dune should be able to resolve that package from the workspace lock directory (e.g. `dune.lock/<name>.pkg`) when the package is locally built via the lockdir mechanism.

Currently, if a rule depends on `(package foo)` and the lock directory defines `foo` (either as an installed program via an `install` action, or as a `source` + `build` that produces an installable package), Dune still fails to resolve the package-provided executables. In practice, actions that try to run or expand the package’s installed binaries fail with an error like:

```
Error: Program foo not found in the tree or in PATH
 (context: default)
```

This happens even though `dune.lock/foo.pkg` exists and describes how to obtain/build/install `foo`.

Dune needs to change `(package ...)` dependency resolution so that, when a lock directory is present, packages referenced via `(package <name>)` are looked up in the lock directory’s package set and treated as available dependencies. After the fix, depending on `(package foo)` must correctly make `foo`’s installed artifacts (notably the `bin/foo` program) available for actions like `(run which foo)` and expansions like `%{bin:foo}` within the build context.

Expected behavior: with a lock directory containing a definition for package `foo`, building an alias that has `(deps (package foo))` and then runs `foo` (or expands `%{bin:foo}`) should succeed without requiring `foo` to already be on the system PATH.

Actual behavior: Dune does not consider lockdir packages for `(package ...)` resolution, so `foo` is not found and the build fails with the program-not-found error shown above.