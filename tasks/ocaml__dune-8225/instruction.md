Dune’s package build language needs to support OPAM-style “substs” by providing an action that can generate an output file from an input template by performing percent-form substitutions.

Implement a package build action spelled `(substitute <input> <output>)` (also referred to as “subst” in the linked issue) that can be used inside a package build `(progn ...)` sequence. When executed, it must read the `<input>` file from the package source, apply OPAM-like substitutions on placeholders, and write the result to `<output>` in the build directory.

The action must work regardless of filename suffixes; it is not restricted to `.in` inputs or to outputs that are the input name without `.in`. For example, `(substitute foo.ml.template not-a-prefix)` must create the file `not-a-prefix` containing the substituted content of `foo.ml.template`.

Substitution syntax to support:
- Template text may contain placeholders of the form `%%{var}%%` which should be replaced by the value of `%{var}%` if defined.
- If a variable is not defined, it must be substituted with the empty string.
- The action must preserve all other text exactly.

Variables that must be defined during package builds include at least:
- `name` and `_:name` (both should resolve to the package name)
- `version`
- Path variables resolving to the package’s install-layout directories under the package target, including: `lib`, `lib_root`, `libexec`, `libexec_root`, `bin`, `sbin`, `toplevel`, `share`, `share_root`, `etc`, `doc`, `stublibs`, `man`
- Environment-provided variables set via `(withenv ((= custom defined-here)) ...)` must be visible to `substitute` so that `%%{custom}%%` expands to `defined-here`.

Example behavior:
- Given an input containing `We substitute this '%%{var}%%' into '%{var}%'`, running `(substitute variables.ml.in variables.ml)` should produce output containing `We substitute this '%{var}%' into ''` (undefined vars become empty).
- Given an input containing `We substitute '%%{name}%%' into '%{name}%'` and package name `test`, the output should contain `We substitute '%{name}%' into 'test'`.

The action must be usable in the package build step so that after running `dune build .pkg/<pkgname>/target/`, subsequent actions like `(system "cat <output>")` can read the generated file successfully. If the action is not recognized, incorrectly parsed, or does not create the output file with substitutions applied, the build should be considered broken.