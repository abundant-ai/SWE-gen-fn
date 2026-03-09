When building Dune packages from a lock directory, package build artifacts and installation targets are currently not correctly isolated per build context. This causes several user-visible problems:

1) Package builds should be performed in a context-specific private build area, so that each build context uses its own package root under `_build/_private/<context>/.pkg/...` and does not interfere with other contexts.

A workspace can define multiple contexts, each with its own lock directory. For example, one context can use `foo.lock` and another context named `foo` can use `bar.lock` (which may be a symlink to `foo.lock`). When building a package target for the default context, the package build must resolve the lock directory associated with that context and run build actions with `%{context_name}` matching the context being built. Building the package in the default context must print `building from default` for an action like:

```
(build (system "echo building from %{context_name}"))
```

2) The `.install` file handling for packages should correctly report missing required entries.

If a package build generates a `.install` file that references a file that was not actually produced, the build must fail with a clear “No such file or directory” error pointing to the missing file being required by the package’s `target`. For example, if the generated install file contains a required entry like:

```
lib: [ "myfile" ]
```

and `myfile` was not created, the build should fail with an error of the form:

```
Error: No such file or directory
-> required by _build/_private/default/.pkg/<pkg>/target
```

However, if the install entry is marked optional (prefixed with `?`), then the build must not fail when the file is missing, e.g.:

```
lib: [ "?myfile" ]
```

3) Packages that perform install actions must install into the package target directory, and Dune must create the standard install layout directories (bin, lib, share, etc.) in the package’s target tree.

For an install action like:

```
(install (system "echo foobar; mkdir -p %{lib}; touch %{lib}/xxx"))
```

building the package should print `foobar`, and the resulting package target tree must include the standard directories as well as the installed file (e.g. `lib/xxx` under the package target root). Dune must also be able to report a “cookie”/metadata describing installed files, including entries like `LIB_ROOT` pointing at the installed path in the build directory.

4) Some environment variables must be automatically exported when executing package build actions so that dependent packages can locate installed artifacts.

When building a package that depends on another package, the dependent package’s build actions should see environment variables updated to point into the dependency’s package target tree, including:

- `MANPATH`
- `OCAMLPATH`
- `CAML_LD_LIBRARY_PATH`
- `OCAMLTOP_INCLUDE_PATH`
- `PATH`

These variables should be prefixed/extended such that tools and libraries installed by dependencies are discoverable from within the dependent package build.

5) Installed binaries from packages must be runnable from dependent packages, but must not automatically become available to the regular workspace build unless explicitly wired.

If a package installs a binary (e.g. installs `foo` into the package target `bin` directory) and another package depends on it, then within the dependent package build it must be possible to `(run foo)` successfully.

At the same time, attempting to run `%{bin:foo}` from ordinary workspace rules (outside the package build environment) should still fail with an error like:

```
Error: Program foo not found in the tree or in PATH
 (context: default)
```

6) Substitution in package sources must work for arbitrary input/output filenames and must handle undefined variables.

Given a source directory copied into the package build, calling:

```
(substitute <input> <output>)
```

must:
- Allow `<input>` to use any suffix (not only `.in`), and allow `<output>` to be any filename.
- Replace occurrences of `%%{var}%%` with the value of the variable `var` if defined, or with the empty string if undefined.
- Provide standard variables such as `name`, `version`, and install path variables like `lib`, `lib_root`, `bin`, etc., so that substitution can produce outputs containing correct context-relative paths inside `_build/_private/<context>/.pkg/<pkg>/target/...`.

Implement/fix the package build pipeline so these behaviors hold consistently, particularly ensuring that package builds and installed artifacts live under the per-context private build area and that context-specific lock directory selection is respected.