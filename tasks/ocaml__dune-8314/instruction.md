`dune pkg lock` has a solver environment that influences package solving. Currently, users cannot configure certain opam build configuration variables (notably `make` and `jobs`) via a workspace context, and `make` cannot be automatically derived from the user’s `PATH` in the same way dune resolves executables for `%{exe:...}` pforms. In addition, the `--just-print-solver-env` flag prints the solver environment in a format that is no longer suitable as the environment grows.

Update the solver environment handling so that:

1) Workspace configuration can set the opam variables `make` and `jobs` per build context (e.g. in a context’s `solver_env` configuration). These should behave like build configuration variables (with distinct semantics from other opam variables), and they must be readable by the solver environment machinery in a uniform way alongside flags (like `with-doc` / `with-test`) and system variables (like `os`).

2) When `make` is not explicitly set, it should be derived from the user’s `PATH` using the same executable-resolution logic as `%{exe:make}` (i.e., find the `make` executable on PATH and use that path as the value). This derivation should be done through the solver environment’s variable access mechanism rather than ad-hoc code paths.

3) The `--just-print-solver-env` output must change from a compact single-expression style into a more verbose, human-readable nested list grouped by variable kind. Running `dune pkg lock --just-print-solver-env` with no workspace should print:

Solver environment for context default:
- Flags
  - with-doc = true
  - with-test = true
- System Environment Variables
  - arch (unset)
  - os (unset)
  - os-version (unset)
  - os-distribution (unset)
  - os-family (unset)
- Constants
  - opam-version = 2.2.0~alpha-vendored

When multiple contexts are configured and `--all-contexts` is passed, the command should print one such block per context, with context-specific overrides reflected. For example, if a context disables `with-doc`, then the printed flags must show `with-doc = false`. If a context sets `sys.os` to `linux`, then the printed system variables must show `os = linux` for that context while other system fields remain “(unset)” unless provided.

The current behavior does not allow configuring these build config variables or deriving `make` from PATH via the same resolution mechanism, and the printed solver environment format does not match the required nested grouped output. Implement the missing configuration support and adjust solver-env printing so these scenarios behave as described.