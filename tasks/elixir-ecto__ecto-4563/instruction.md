Ecto’s query API currently exposes `literal/1` for injecting literal values into queries, but its semantics have become problematic/unclear—particularly around allowing numbers and distinguishing between SQL identifiers (like column/table names) and constant values. The existing behavior needs to be adjusted by deprecating the old `literal/1` and introducing two new query helpers: `identifier/1` and `constant/1`, each with a clear, distinct purpose.

When building queries, developers need to be able to explicitly mark:

1) SQL identifiers that should be treated as identifiers (not quoted/bound as values). For example, dynamic column names or fragments that must be interpreted as identifiers should be expressible via `identifier/1`.

2) Constant values that should be embedded as constants (not treated as identifiers). For example, numeric or string constants that are intended to be constants in the generated query should be expressible via `constant/1`.

Currently, using `literal/1` for these cases is either ambiguous or behaves incorrectly (notably around numeric literals), and the recently added behavior that “allows numbers in `literal/1`” must be reverted.

Implement `Ecto.Query.identifier/1` and `Ecto.Query.constant/1` so they can be used inside query expressions (e.g., in `where`, `select`, etc.) without breaking query compilation. The old `Ecto.Query.literal/1` must remain accepted for backwards compatibility but should be treated as deprecated in favor of the two new functions. Existing query compilation rules (for example, forbidding comparisons with `nil` at compile time and runtime) must continue to behave the same; introducing these helpers must not regress macro usage or general query building.

After the change, callers should be able to write queries using `identifier/1` and `constant/1` to disambiguate intent, and numeric usage that was recently permitted through `literal/1` should no longer be the supported path (use `constant/1` instead).