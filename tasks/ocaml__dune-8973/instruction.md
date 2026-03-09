`dune pkg lock` should persist information about which solver variables were actually evaluated during dependency solving, and what values they had, into the lock directory metadata (the `lock.dune` file). Currently, lock directories do not record these evaluated variable bindings, which makes it impossible to tell (from the lockdir alone) what environment-dependent assumptions influenced the solver result.

Add support for a new lockdir metadata field named `expanded_solver_variable_bindings` that stores:

- `variable_values`: an association list of evaluated solver variables to their concrete values (for example `os` and `arch` coming from `solver_sys_vars` in the workspace context).
- `unset_variables`: a list of solver variables that were evaluated but had no value available (i.e., were effectively unset at solve time).

This metadata must be written when generating a lockdir and must round-trip correctly through disk: encoding then decoding a lockdir must preserve `expanded_solver_variable_bindings` exactly (modulo locations), and lockdir equality after a write/read cycle must succeed.

Behavior requirements:

1. For packages whose dependency constraints do not consult any solver variables, `expanded_solver_variable_bindings` should be absent from the generated `lock.dune` (or otherwise represent an empty binding set) and must not introduce spurious variables.

2. For packages whose dependency constraints use solver variables in filters (e.g. constraints like `os = linux` or `arch = arm`), `expanded_solver_variable_bindings` must be present and must include every solver variable whose value was consulted while evaluating those filters.

3. When no workspace `solver_sys_vars` are provided and a filter consults a variable, that variable must be recorded under `unset_variables`.

4. When workspace `solver_sys_vars` are provided (e.g. `os linux` and `arch arm`), consulted variables with available values must be recorded under `variable_values` with the exact string values used by the solver.

5. Lazy boolean filter evaluation must be reflected accurately: if an expression like `A | B` short-circuits such that `B` is not evaluated, then variables appearing only in `B` must NOT be recorded as evaluated. Conversely, variables evaluated before a short-circuit must be recorded. For example, solving dependencies with filters like `os = linux | os-family = ubuntu` and `arch = arm | os-version = "22.04"` should record `os` and `arch` as evaluated, and only record `os-family`/`os-version` as evaluated when they are actually reached during evaluation; if they are not reached, they should not appear in `expanded_solver_variable_bindings`.

APIs/types involved that must support this end-to-end:

- `Dune_pkg.Solver_stats.Expanded_variable_bindings` should represent these bindings, with an `empty` value.
- `Dune_pkg.Lock_dir.create_latest_version` must accept and store `~expanded_solver_variable_bindings`.
- `Dune_pkg.Lock_dir` disk encoding/decoding must include the `expanded_solver_variable_bindings` field and preserve it on a write/read round-trip.

The generated `lock.dune` metadata must render the field using the following shape when non-empty:

```
(expanded_solver_variable_bindings
 (variable_values
  (os linux)
  (arch arm))
 (unset_variables os-version os-family))
```

When variables are unset and no values exist, it must render only `unset_variables`, e.g.:

```
(expanded_solver_variable_bindings
 (unset_variables os arch))
```

The goal is that `dune pkg lock` produces lockdirs whose metadata captures the solver’s evaluated variable environment precisely and deterministically, and that reading back an on-disk lockdir reconstructs the same `Lock_dir.t` (including `expanded_solver_variable_bindings`).