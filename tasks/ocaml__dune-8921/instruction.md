When building opam packages through Dune’s pkg integration, certain opam “switch variables” (notably `%{prefix}` and derived locations like `%{lib}`, `%{bin}`, etc.) are being expanded too early, at rule generation time. This early expansion can produce relative paths for values that must be absolute when passed to configure/install logic, which causes builds of some packages (e.g., ocaml/ocaml-variants via ocaml-config/ocaml) to fail.

A typical failure looks like:

```
configure: error: expected an absolute directory name for --prefix: ../target
-> required by _build/_private/default/.pkg/ocaml-variants/target/cookie
-> required by - package ocaml-config
-> required by - package ocaml
```

At the same time, always forcing these variables to absolute paths at rule generation time is not acceptable because it can break caching: paths become tied to the build directory in a way that prevents effective reuse.

The package action/command expansion must therefore delay path expansion until action execution time (i.e., when the sandbox/build directory is known), so that:

- Values like `%{prefix}` are provided to executed commands as absolute paths (satisfying tools like `configure` that require absolute `--prefix`).
- Derived variables `%{lib}`, `%{libexec}`, `%{bin}`, `%{sbin}`, `%{share}`, `%{doc}`, `%{etc}`, `%{man}`, `%{toplevel}`, `%{stublibs}` resolve consistently under the package’s target directory.
- `%{switch}` should continue to resolve to the single switch name used by Dune ("dune").
- `%{build}` should resolve to the package’s build/source directory.

Reproduction scenario: create a package whose build commands print these variables (or pass `%{prefix}` to a `configure`-style script that rejects relative prefixes). Running the package build should print absolute, sandbox-local paths for `%{build}`, `%{prefix}`, and all derived install locations, and should no longer error with “expected an absolute directory name for --prefix”.