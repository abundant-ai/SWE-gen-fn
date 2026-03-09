When running `dune pkg lock` against an opam repository, opam command filters attached to build/install command entries (the `{ ... }` filter syntax on an entire command) are not being converted into Dune actions correctly. The lockdir generation should translate these command-level opam filters into Dune’s `when` action so that commands become conditionally executed based on the filter expression.

Currently, command filters may either be ignored, produce incorrect conditional logic (especially around operator precedence), or cause failures in the lock step for some expressions. In addition, encountering the opam unary `?` operator (which checks whether a variable is defined) currently triggers an internal “code error” rather than producing a user-facing, actionable error.

Fix the conversion so that `dune pkg lock` can successfully process packages whose opam files contain command entries like:

- Single variable conditions: `{ foo }`
- Boolean combinations with correct precedence and parentheses: `{ foo & bar }`, `{ foo | bar & baz }`, `{ (foo | bar) & baz }`, `{ ! false }`
- Comparisons and string/number comparisons: `{ foo = bar }`, `{ version < "1.0" }`, `{ ocaml:version < "5.0.0" }`
- Built-in flags combined with other checks: `{ with-test & ocaml:version < "5.0.0" }`
- Package-scoped variables and package predicates: `{ foo:installed }`, `{ foo:version < "0.4" }`, `{ foo+bar+baz:installed }`

Expected behavior:
- `dune pkg lock` succeeds and produces conditional Dune actions equivalent to the original opam command filters (i.e., the command is wrapped in a `when` condition that matches the opam filter semantics).
- Operator precedence matches opam filter rules (`!` binds tighter than `&`, which binds tighter than `|`; parentheses must be preserved).
- Variable interpolation in command arguments continues to work and should not be confused with percent signs that are not interpolation sequences.

Error handling requirements:
- If a filter contains an invalid package-variable conjunction such as `foo+bar+baz:version < "0.4"` (where the left side is a package list but the variable requires a single package context), `dune pkg lock` should fail with a clear, user-facing error explaining the invalid filter usage.
- If a filter uses a boolean expression where a string is required (for example comparing a version to `(foo = bar)`), the failure should be a parsing/validation error with a clear message rather than an internal exception.
- If the unary `?` operator appears in a command filter, `dune pkg lock` must not raise an internal “code error”. It should instead fail gracefully with an explicit message stating that `?` (definedness checks) is not supported in command-filter conversion (or otherwise handle it correctly if support is implemented).

The goal is that packages using these command-level opam filters can be locked without crashing, and the resulting conditional execution behavior matches opam semantics as closely as possible via Dune’s `when` action and boolean language (blang) expressions.