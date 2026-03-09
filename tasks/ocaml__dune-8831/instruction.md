When configuring OPAM repositories for `dune pkg` via `dune-workspace`, repository lists are currently treated as a simple list rather than an ordered-set expression. This causes two user-visible problems:

1) The `repositories` field in a context’s `(solver_env ...)` does not support Ordered Set Language features such as `:standard` or set subtraction (e.g. `\`). Users cannot write expressions like `(:standard \ new)` to exclude a repository, and `:standard` is not interpreted consistently.

2) Using more than one OPAM repository does not behave correctly. In a workspace that defines multiple `(repository (name ...) (source ...))` entries, selecting repositories in `(solver_env (repositories ...))` should control which repositories are used for locking and dependency resolution, but currently only a single repository is effectively used or repository selection is ignored/incorrectly merged.

Expected behavior:

- `dune pkg lock` must correctly honor multiple repositories selected for a context. If two repositories contain the same package name with different versions, the chosen repositories must determine the result:
  - If only `new` is selected, locking should resolve to the package versions available in `new` (e.g. `foo.2.0`).
  - If only `old` is selected, locking should resolve to the versions in `old` (e.g. `foo.1.0`).
  - If both `new old` are selected, locking should still resolve consistently according to the intended repository ordering/priority, so the newer package from `new` is selected when both provide it.

- Repository selection must support Ordered Set Language, so users can write repository sets rather than only a plain list. In particular:
  - `:standard` must be supported for repositories (so users get the default repository set without redefining it).
  - Set operations must work, including excluding repositories from a set, such as `(:standard \ new)`.
  - The configuration should accept ordered-set expressions in the workspace for repository selection (including both the legacy `repositories` form and the newer `repo`/set-style form if both are supported), and produce the correct effective set.

- `dune pkg print-solver-env` should display the repositories selected for each context consistently, showing the default repository when no workspace is present, and reflecting any repository-set changes when a workspace defines contexts.

Actual behavior to fix:

- Ordered-set expressions for repositories are not handled, so `:standard` and set subtraction do not work for repository selection.
- With multiple configured repositories, `dune pkg lock` does not reliably use the repositories specified in the context, leading to incorrect package versions being selected.

Implement repository list parsing and solver environment handling so that repository selection is represented using Ordered Set Language, and ensure the locking/solver pipeline uses the resulting ordered set when fetching repository indexes and resolving packages. This should also preserve correct behavior for downloading repository indexes from a URL (e.g. `--opam-repository-url=...`) while allowing multiple repositories to coexist and be selected per-context.