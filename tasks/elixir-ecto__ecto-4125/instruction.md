Constraint matching in Ecto currently relies on exact, prefix, or suffix matching of the database constraint name when translating database errors into user-facing constraint errors (for example via changeset constraint helpers and repo operations that surface constraint violations). This breaks down for databases that generate constraint/index names with variable numeric segments in the middle and/or end (such as partitioned PostgreSQL tables producing names like `partition_table_XXX_index_name_idx_YY`).

When a constraint violation is raised with a concrete constraint name containing these variable segments, Ecto should be able to match it against a user-provided pattern rather than requiring a fixed string or simple prefix/suffix.

Implement support for a new constraint matcher `:regex`.

When a constraint is declared with `match: :regex`, the constraint’s `name` value must be treated as a regular expression pattern. Ecto should compile that pattern and consider the constraint matched if the raised database constraint name matches the compiled regex.

Expected behavior:

- Declaring a constraint with `match: :regex` allows matching constraint names where variable parts appear anywhere in the name (middle or end), not just at the beginning or end.
- For example, if the raised constraint is `partition_table_123_index_name_idx_45`, and the constraint is declared with something like `name: "partition_table_\\d+_index_name_idx_\\d+", match: :regex`, Ecto should treat the raised error as matching that constraint.
- Existing matching modes must continue to behave as before; adding `:regex` must not change the semantics of exact/prefix/suffix matching.

Actual behavior to fix:

- Without `:regex` support, constraints with generated names that include variable numeric segments cannot be reliably matched, so Ecto fails to associate the database error with the declared constraint and does not produce the expected constraint error on the changeset (or otherwise fails to translate the constraint violation appropriately).

The implementation must ensure that the regex matching is applied at the point where Ecto compares a declared constraint definition (its `name` and `match` mode) against the constraint name coming from the database exception, so that the correct constraint entry is selected when `match: :regex` is used.