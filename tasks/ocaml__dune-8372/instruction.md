When converting opam `build:`/`install:` command arguments into Dune lockdir actions, package-scoped variables are currently handled via special-cased pform variables like `Name` and `Version`, and other variables may be treated as “unknown” and handled differently. This behavior is incorrect because opam variables like `name` and `version` are inherently package-scoped (even when written without an explicit package qualifier), and opam also allows custom package variables.

Update the opam-command conversion so that package variables are represented using the `%{pkg:...}` macro form, and remove reliance on the dedicated `Name` and `Version` pkg pform variables.

Concretely:
- In an opam command such as `dune build -p name -j jobs @install`, the unqualified variable `name` must be converted to a package-scoped macro and end up in the generated Dune action as `-p %{pkg:var:_:name}` (with the package scope made explicit via `pkg`).
- Non-package-scoped variables like `jobs` must continue to be converted to the existing non-package form (e.g. `-j %{jobs}`).
- Explicitly package-scoped opam variables (when present in opam commands) must also be supported during conversion and must map to the `%{pkg:...}` macro form.
- The conversion must no longer need to special-case or reject “unknown variables” simply because they aren’t in a fixed set; custom package variables should be representable via `%{pkg:...}` rather than triggering fallback handling.

Expected behavior is that the generated lockdir package file contains actions where package variables use `%{pkg:...}` (e.g. `run dune build -p %{pkg:var:_:name} -j %{jobs} ...`) and that `Name`/`Version` pkg pform variables are not used anymore. Currently, conversion output uses the legacy variables and/or treats some variables as unknown, causing generated commands to not match the desired macro form for package variables.