Elixir currently fails to consistently detect and report redundant (unreachable) clauses in function and macro definitions. In particular, when a definition has multiple clauses, clauses that can never match due to earlier clauses being strictly more general (or otherwise covering all possible inputs) are not reliably flagged as redundant, or they may be checked in some contexts (like certain expressions) but not for definitions.

This needs to be fixed so that redundant-clause analysis is performed for definitions in a way that is consistent with how redundancy/unreachability is determined for other pattern-matching constructs.

The expected behavior is that when defining a function or macro with multiple clauses, the compiler should identify clauses that are unreachable because previous clauses will always match first, and emit an appropriate diagnostic (warning) for those redundant clauses. This should work across:

- Multi-clause `def`/`defp` and `defmacro`/`defmacrop` definitions
- Clauses with patterns, pinned variables, and guards (including guard-only distinctions)
- Clauses involving literals and sign-prefixed numeric literals (such as `-1` and `+1` in patterns)
- Definitions in modules that also use aliases and imported/captured functions (ensuring the redundancy analysis does not break or get confused by aliasing/capture forms)

The diagnostic should be stable and precise: it should point to the redundant clause and avoid false positives (do not warn when a later clause is actually reachable due to a more specific pattern or a guard that changes matchability).

Example scenarios that should be handled correctly:

- If the first clause is a catch-all (like `_` or a variable pattern without a guard), any subsequent clause for the same arity should be reported as redundant.
- If the first clause matches a specific value (like `1`) and the second clause is a catch-all, no redundancy warning should be emitted.
- If two clauses differ only by guards, the later clause should only be considered redundant if the earlier guard condition fully covers it; otherwise it must remain reachable.

Implement redundant-clause checking for definitions so these cases behave correctly and diagnostics are emitted only when appropriate.