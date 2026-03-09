Dune’s opam-package integration exposes global opam variables (e.g. through `%{...}` expansions in generated build actions). System-specific variables are currently incorrect/incomplete: the `os` opam variable is missing entirely, and some related OS variable names are mapped incorrectly. This causes builds that rely on opam OS variables to produce the wrong values (or fail to expand), and makes Dune’s `%{...}` values disagree with what `opam var` reports on the same machine.

Repro scenario: create an opam package whose `build:` actions reference the system variables `arch`, `os`, `os-distribution`, `os-family`, and `os-version` (as opam variables), then have Dune lock/translate that package and run the build. The generated build steps should expand these variables as `%{arch}`, `%{os}`, `%{os_distribution}`, `%{os_family}`, and `%{os_version}` and the runtime-expanded values should match the corresponding outputs of:

- `opam var arch`
- `opam var os`
- `opam var os-distribution`
- `opam var os-family`
- `opam var os-version`

Actual behavior: `%{os}` is not provided (or expands incorrectly), and one or more of the OS-related variables use incorrect names/mappings (for example, hyphenated opam variables like `os-distribution` should correspond to the underscore form used in Dune variable syntax, and the values should match opam’s).

Expected behavior: Dune must provide the missing global opam variable `os`, and all supported OS-related variables must use the correct names and mappings so that, when a package build action echoes these variables, the captured output is identical to what `opam var` returns for the same variables on that system. This should hold across different machines/OSes, so the implementation must not hardcode specific OS values; it must correctly forward/compute them the same way opam does.