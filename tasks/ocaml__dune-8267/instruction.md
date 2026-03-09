Running `dune pkg lock --just-print-solver-env` should always include a `sys` solver variable named `opam-version`, set to the version of opam vendored inside Dune. Currently, `opam-version` is not reliably set during solving (or can vary/be absent depending on context configuration), which means the printed solver environment and the actual solving environment can be missing this required variable.

The solver environment printed for a context must include `opam-version` alongside any other `sys` variables and `flags`. For example, when no workspace configuration is present, `dune pkg lock --just-print-solver-env` should print something like:

```
Solver environment for context default:
((flags (with-doc with-test)) (sys ((opam-version <vendored-opam-version>))))
```

When multiple contexts are used (e.g. via `--all-contexts`) and a context defines additional `solver_env` entries, the final solver environment must still include `opam-version` in `sys` for every context, merged with the user-provided `solver_env` values. For example, if a context sets `sys (os linux)`, the printed environment should include both:

```
(sys ((opam-version <vendored-opam-version>) (os linux)))
```

Users must not be allowed to override the `opam-version` solver variable from workspace configuration. If a context attempts to set `solver_env (sys (opam-version foo))`, `dune pkg lock --all-contexts --just-print-solver-env` must fail with an error message of the form:

```
Error: Context <context-name> would override solver
variable opam-version. This variable may not be overriden.
```

Implement the behavior so that `opam-version` is always injected into the solver environment for every context during solving/printing, and ensure an explicit user attempt to set `opam-version` is detected and rejected with the error above.