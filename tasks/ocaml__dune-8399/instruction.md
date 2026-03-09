The package-variable macro syntax used in command interpolation needs to be updated to a new, more concise format, and the conversion layer that translates opam commands into dune package build/install commands must emit the new syntax consistently.

Currently, package variables are referenced via the `pkg` macro in a verbose form that is no longer desired. The macro should support concise, colon-separated encodings for package variables and the “self package” variables, and these encodings must round-trip correctly through encoding/decoding logic so that changing formatting doesn’t require touching multiple callers.

When users define variables for a package and then reference them in build commands, interpolations like `%{pkg:<package>:<var>}` must resolve to the value defined for that package variable. For example, if package `test` defines variables `abool = true`, `astring = "foobar"`, and `somestrings = ["foo" "bar"]`, then interpolations `%{pkg:test:abool}`, `%{pkg:test:astring}`, and `%{pkg:test:somestrings}` should expand to `true`, `foobar`, and `foo bar` respectively.

The opam-to-dune command conversion must produce the updated macro forms in generated `.pkg` files:
- When opam uses the `name` variable in a context where it refers to the current package name (e.g. `-p name`), the generated command must use the “self package” macro form `%{pkg-self:name}`.
- When opam refers to package variables that are local to the current package (e.g. `local_var` or `_:explicit_local_var`), the generated commands must use `%{pkg-self:local_var}` and `%{pkg-self:explicit_local_var}`.
- When opam refers to a package variable belonging to another package (e.g. `foo:package_var`), the generated command must use the concise package-variable form `%{pkg:package_var:foo}` (variable name first, then package name).
- Non-package variables such as `jobs`, `make`, `prefix`, `doc`, and `os-family` must continue to interpolate as their appropriate non-`pkg` pforms (e.g. `%{jobs}`, `%{make}`, `%{prefix}`, `%{doc}`, `%{os_family}`), and should not be rewritten into `pkg` macros.

Interpolation parsing must remain correct for literal percent signs and malformed opam interpolation syntax:
- Percent signs that are not part of opam interpolation (for example a command argument like `%d`) must remain unchanged in the converted output.
- If an opam command contains malformed interpolation like `--prefix=%{prefix` (missing closing `}%` in opam syntax), locking/conversion must fail with an error stating:
  - `Error: Encountered malformed variable interpolation while processing commands for package <pkg>.`
  - It must include the malformed interpolation snippet (e.g. `%{prefix`) and the full command that contained it (e.g. `"./configure" "--prefix=%{prefix"`).

Implement the encoding/decoding layer for package variables as pforms so that all parts of the system (variable evaluation, macro printing/parsing, and opam command conversion) agree on the new concise `pkg`/`pkg-self` formats and the above behaviors work end-to-end.