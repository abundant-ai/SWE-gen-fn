Dune’s package lock/solver currently does not apply opam semantics for the `installed` package variable early enough. In opam, when a referenced package is not part of the solution, that package’s `installed` variable is known and must evaluate to boolean false. Dune should take advantage of this at solve time (before writing the lockfile) by substituting `installed=false` for any `%{pkg:<absent>:installed}`-style reference where `<absent>` is not selected in the final solution.

This incorrect behavior shows up in multiple syntactic contexts:

1) Bare variable in command arguments: when a package contains a build command argument like `absent:installed`, it should resolve to the string `false` in the generated lockfile action (because it’s a string context).

2) String interpolation: when a command argument contains `%{absent:installed}%`, the interpolation should resolve to `false`.

3) Ternary/string converter form: `%{absent:installed?yes:no}%` should evaluate to `no` because `installed` is false.

4) Filter context: build commands guarded by `{absent:installed}` must be removed entirely (always-false filter), and commands guarded by `{!absent:installed}` must remain but with the filter simplified away (always-true after substitution).

Additionally, depext filtering at lock time should treat `pkg:installed` as a standard variable only when the referenced package is actually present in the solution. Depext entries using a bare unknown variable (e.g. `{foobar}`) must be dropped. Depext entries referencing a known package but a non-standard/unknown variable (e.g. `{dep:nonexistent-var}`) must be dropped. Depext entries referencing `dep:installed` where `dep` is in the solution must be kept and recorded as `%{pkg:dep:installed}`. References to `nonexistent-pkg:installed` (package not in the solution) should not be treated as a meaningful condition; `installed` should be substituted to false at solve time for absent packages so that such conditions can be simplified and, where applicable, filtered out.

The lockfile that Dune generates should reflect these solve-time substitutions by emitting concrete actions (e.g. `run echo false`, `run echo no`) and by not preserving always-true/always-false filters once they are determined by `installed=false` for absent packages.