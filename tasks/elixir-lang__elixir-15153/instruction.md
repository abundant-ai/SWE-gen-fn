The Elixir compiler’s type checking/verification can become extremely slow or appear to hang when analyzing functions with many clauses whose patterns/guards produce progressively refined types. This is particularly visible when multiple clauses match on different map key sets (and then later access keys not present in some patterns) and when there are enough clauses (around 20+), as well as in code with multiple layers of functions with many guarded clauses.

The slowdown is caused by how type “differences” are computed and accumulated across successive clauses. The current behavior incorrectly nests differences when building the type for later clauses. For a function with multiple clauses, the type for the Nth clause is being computed using a nested structure equivalent to:

    clause4 - (clause3 - clause2 - clause1) - (clause2 - clause1) - clause1

rather than the intended flat subtraction:

    clause4 - clause3 - clause2 - clause1

This nesting causes the amount of work to grow as an arithmetic progression (n*(n+1)/2) instead of linear in the number of clauses, leading to severe compile-time regressions and, in some cases, effectively unbounded compilation times.

Fix the type difference computation so that differences across multiple clauses are simplified/accumulated correctly (flat differences instead of nested differences). The fix must ensure that type checking/verification for code with many clauses and refinements completes in reasonable time and does not exhibit the pathological growth described above.

Reproduction examples include:

1) A function with multiple clauses where some clauses pattern match on one map key set (e.g., only `status`) while other clauses pattern match on different key sets (e.g., `category` and `kind`) and then access `data.status`. With enough clauses, compilation/type checking should complete promptly; it currently becomes extremely slow/hangs.

2) Multiple functions (`foo/1`, `bar/1`, `baz/1`) each with several clauses using guards built from repeated checks (e.g., `tuple_size/1`, `elem/2`, and membership checks like `in`), where one function calls the next. Type checking should not degrade dramatically with such repeated guarded clauses.

After the change, the semantics of type checking must remain correct (no “corruption” of inferred information across clauses), but compilation speed must no longer degrade dramatically on these patterns. In particular, repeated refinements/differences across clauses should not create deeply nested difference structures that explode work as more clauses are added.