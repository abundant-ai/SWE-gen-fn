`dune pkg lock` should copy `build:` and `install:` commands from a package’s opam file into the generated lockdir package file, translating opam command/argument forms into Dune lockfile actions.

When a dependency’s opam file contains `build:` and/or `install:` stanzas, the corresponding generated `<pkg>.pkg` entry must include `(build ...)` and `(install ...)` forms that preserve command order and translate commands to `(run ...)` actions. For example, given an opam file with:

```
build: [
  ["dune" "subst"] {dev}
  [
    "dune" "build" "-p" name "-j" jobs "@install"
    "@runtest" {with-test}
    "@doc" {with-doc}
  ]
]
install: [ make "install" ]
```

running `dune pkg lock` should produce a lock package file whose relevant fields are equivalent to:

```
(install (run %{make} install))
(build (progn (run dune subst)
             (run dune build -p %{name} -j %{jobs} @install @runtest @doc)))
```

Key requirements:
- Multiple opam commands in `build:` must become a single `(build (progn ...))` with one `(run ...)` per command, in the same order.
- Known opam variables used as arguments must be converted to Dune variable syntax:
  - `name` → `%{name}`
  - `jobs` → `%{jobs}`
  - `make` (when used as a command) → `%{make}`
- Unsupported opam features are allowed to remain unsupported (filters on commands/arguments, string interpolation, non-`_` package-scoped variables, and actually executing the actions), but the conversion logic must correctly handle the supported subset above.

If an opam command references an unknown/unsupported variable in a position where a command/argument is expected (e.g. `build: [ fake "install" ]`), `dune pkg lock` must fail with a clear error that includes:
- The unknown variable name in quotes.
- The package name and version being processed.
- The full opam command as written.

Example error format:

```
Error: Encountered unknown variable "fake" while processing commands for
package with-unknown-variable.0.0.1.
The full command:
fake "install"
```

Currently, `dune pkg lock` does not reliably emit these `(build ...)` / `(install ...)` actions from opam files or does not provide the required error when unknown variables appear; implement the conversion and error behavior described above.