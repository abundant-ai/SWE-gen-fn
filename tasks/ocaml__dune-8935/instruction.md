Dune’s package solver workspace configuration has been refactored to clarify the meaning of two fields, but the current behavior is inconsistent with the new names.

The workspace context fields that influence the solver must be renamed as follows:

1) The context field currently written as `(sys ...)` (used to affect the solver’s system variables) is being replaced by `(override_solver_sys_vars ...)`. These values must override the solver system variables that would otherwise come from polling the host system. When the user disables polling (e.g. via `--dont-poll-system-solver-variables`), the solver environment for each context should still reflect the overrides provided by the workspace.

2) The context field currently written as `(repositories ...)` is being replaced by `(default_repositories ...)`. These repositories are only defaults: they should be used only when no repositories were explicitly provided through other means. When repositories are explicitly set for a context (or provided via command-line configuration), those must take precedence over the defaults.

The following user-visible behaviors must work:

- `dune pkg print-solver-env` must print, for each build context, the solver “System Environment Variables” showing overridden values when `override_solver_sys_vars` is set. For example, if a context sets `(override_solver_sys_vars (os linux))`, then the printed environment for that context must show `os = linux`, while other variables not overridden remain “(unset)” when polling is disabled.

- `dune pkg lock --all-contexts --dont-poll-system-solver-variables ...` must produce solutions that differ per context according to `override_solver_sys_vars`. For example, a package with conditional dependencies on `os` must include the linux-only dependency in the linux context and the macos-only dependency in the macos context when those contexts override `os` accordingly.

- Repository selection must respect the new default semantics. If a context specifies repositories to use explicitly, those should be used. If a context does not specify repositories, then `default_repositories` (if present in the workspace context) should be used. This must correctly influence which package versions are chosen when multiple repositories provide different versions.

- Any existing configuration still using the old field names must either be handled compatibly (if backward compatibility is intended) or fail with a clear, actionable error indicating the new names to use. In either case, users must not silently get incorrect solver environments or unexpected repository choices.

Overall expectation: updating a dune-workspace to use `override_solver_sys_vars` and `default_repositories` must preserve the previously intended behavior (system-variable overrides affecting solver decisions per context, and repository lists acting as defaults only), and commands like `dune pkg lock` and `dune pkg print-solver-env` must reflect those semantics consistently across contexts.