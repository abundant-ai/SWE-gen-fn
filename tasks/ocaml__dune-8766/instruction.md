The package dependency solver currently treats comparisons against any unset system environment variables ("sys" variables like `os`, `arch`, etc.) as a wildcard that makes the comparison evaluate as true. This causes incorrect dependency selection when a package has mutually exclusive conditions, because the solver can incorrectly consider an OS-specific condition satisfied even when `os` is not defined.

For example, given dependencies like:

```
depends: [
  "uring" {os = "linux"}
  "luv" {!(os = "linux")}
]
```

When the solver environment does not define `os`, the current behavior effectively makes `os = "linux"` evaluate to true, so the solver always picks `uring` and never picks `luv`, even though it should not be making OS-specific choices without an OS value.

Update the solver so that comparisons against unset system environment variables do not behave like wildcards. Instead, solver system environment variables must have a specific value to be used for conditional dependency/availability evaluation. If a sys variable such as `os` is unset, then expressions like `os = "linux"` must not evaluate to true (and should behave as an unsatisfied condition rather than a match-all).

The solver environment must support explicitly setting these sys variables per build context via workspace configuration (in `dune-workspace`), so different build contexts can solve with different system environments (e.g., one context with `os=linux`, another with `os=macos`). When solving across multiple contexts, each context’s lockdir should reflect its own `solver_env` values.

Required observable behavior:

- When no `dune-workspace` is present (or when a context does not specify `solver_env (sys ...)`), `dune pkg print-solver-env` must show sys variables like `arch`, `os`, `os-version`, `os-distribution`, and `os-family` as `(unset)` for that context.
- If a workspace defines multiple contexts with different `solver_env` settings, `dune pkg print-solver-env --all-contexts` must show the overridden values in the corresponding contexts (e.g., a `linux` context showing `os = linux` while another context still shows `os (unset)` if not set).
- When generating a lockdir, OS-specific dependencies must only be included if the relevant sys variables are set in that context. If `os` is unset, dependencies guarded by `{os = "linux"}` or `{os = "macos"}` must not be selected just because the variable is missing.
- When solving in two contexts with different `os` values (e.g., `linux` and `macos`), each context should select the dependencies/versions that satisfy availability/filters under its own `os` value.
- If a package is only available on a given OS via an `available:` filter, solving in a context with a different `os` must fail with an error indicating that no usable implementations exist because the availability condition is not satisfied.

The overall goal is to remove the wildcard behavior for unset solver system environment variables and ensure dependency solving is deterministic and context-specific, with sys variable values derived from the current system by default but overridable per build context in workspace configuration.