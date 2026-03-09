The build system’s Scheme functionality has been split out into a standalone library, but after the refactor the Scheme API must remain usable exactly as before by other parts of the system and by consumers.

In particular, code that does `include Scheme` and then calls Scheme operations must still compile and behave the same. The following functions and modules must be available and work as expected:

- The `Scheme` module must expose the same constructors and variants (`Empty`, `Union`, `Approximation`, `Finite`, `Thunk`) so that pattern matching over a `'a Scheme.t` still works.
- `Scheme.evaluate` must still exist and accept the `~union` argument (so callers can supply a union operator for directory rule accumulation).
- `Scheme.Evaluated.get_rules` must still exist and return a pair `(rules, ...)` where `rules` is optional; callers rely on being able to do:

```ocaml
let+ rules, _ = Evaluated.get_rules t ~dir in
Option.value rules ~default:Directory_rules.empty
```

- `Scheme` must continue to interoperate with `Dune_engine.Dir_set` and `Path.Build.Map` in the same way as before for approximations and finite rule maps (callers expect to filter approximations using `Dune_engine.Dir_set.mem` and look up directory rules using `Path.Build.Map.find`).

After moving Scheme into its own library, ensure that:

1) The above API surface remains available under the `Scheme` module name (or a compatibility layer exists so dependent code does not need behavioral changes).
2) Evaluation and rule retrieval semantics are preserved: `Approximation (dirs, t)` must hide rules when `dir` is not in `dirs`, and `Finite rules` must return the per-directory rule list when present and an empty rule set when absent.
3) Thunks embedded in Scheme values still run when forced by evaluation/rule collection; callers rely on being able to wrap Scheme values to instrument thunk execution (e.g., wrapping `Thunk (fun () -> ...)` to record when code runs).

The regression to fix is that, after the refactor, Scheme consumers either can’t compile due to missing/renamed modules/functions, or evaluation/rule retrieval no longer matches the expectations above (e.g., approximations not filtering correctly, thunks not being forced, or `Evaluated.get_rules` no longer returning the optional rules in the expected shape). Restore the public API and behavior so downstream code using these functions compiles and produces the same observable results when evaluating schemes and collecting rules by directory.