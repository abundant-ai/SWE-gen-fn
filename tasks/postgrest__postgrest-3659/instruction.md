One-to-one (O2O) relationships are not reliably detected when a foreign key references a composite primary key or composite unique constraint and the columns in the FK definition are not in the same order as the referenced constraint’s column order.

Currently, O2O detection only works if the FK column list happens to be ordered the same way as the target table’s referenced key columns when sorted by the target columns’ `attnum` (physical column order). If the FK is defined with the same column set but in a different order, PostgREST incorrectly classifies the relationship as not one-to-one. As a result, embedding returns the wrong shape: instead of treating the embed as a single object (O2O), it is treated like a to-many relationship (array) or otherwise fails to match the intended O2O behavior.

Reproduction scenario:
- Create two tables where the target table has a composite PRIMARY KEY or a composite UNIQUE constraint (e.g., `(a, b)`).
- Create a referencing table with a FOREIGN KEY that references those same columns but declares the FK columns in a different order (e.g., `FOREIGN KEY (b, a) REFERENCES target(b, a)` or `FOREIGN KEY (b, a) REFERENCES target(a, b)` depending on the DDL). The FK is logically valid and enforced by PostgreSQL.
- Use resource embedding across that relationship.

Expected behavior:
- PostgREST should detect the relationship as one-to-one as long as the FK references a unique set of columns on the target side and the referencing side is also unique in the same column set, regardless of the order in which the columns appear in the FK definition.
- Embedding over this relationship should produce an object (single JSON object or null when missing), consistent with other O2O relationships.

Actual behavior:
- If the FK column order differs from the referenced key’s column order (as derived from `attnum` ordering), PostgREST fails to recognize the relationship as O2O.
- The embed is returned with the wrong cardinality (e.g., as an array) or the relationship is treated as not one-to-one, breaking expected embedding semantics.

Implement the relationship detection so that composite key matching for O2O is order-insensitive: it should match based on the set of paired source/target columns (or otherwise normalize ordering consistently) rather than relying on the target table’s physical column order.