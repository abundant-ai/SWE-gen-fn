When planning queries that use CTEs (common table expressions) with data-modifying operations, the query planner currently has two related problems.

First, CTEs that attempt to use `insert_all` are not actually supported, but they may be accepted or partially planned in a way that later fails unpredictably. Instead, attempting to build/plan a query that includes a data-modifying CTE with an `insert_all` operation should fail deterministically with a clear error indicating that `insert_all` is not supported in data-modifying CTEs.

Second, the query planner caches planned queries, but the cache key does not take the CTE operation into account. As a result, two queries that differ only by the data-modifying CTE operation (for example, one CTE performing an update and another performing a delete, or otherwise differing in the CTE’s modifying operation) can incorrectly share the same cached plan. This can lead to the wrong underlying planned query being reused across operations.

Fix the planner so that:

- Planning a query with a data-modifying CTE that uses `insert_all` is rejected consistently with an explicit error.
- The planner cache key incorporates the CTE data-modifying operation so that changing the operation produces a different cache key and does not reuse an incompatible cached plan.

After the fix, planning the same base query with different CTE modifying operations must not share the same cached plan, and attempting to use `insert_all` in a data-modifying CTE must reliably raise rather than producing a planned query or failing later.