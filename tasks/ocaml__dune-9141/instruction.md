Memo’s metrics/counters support is inconsistent: counters/metrics are not reliably enabled and exposed in a stable way, and invariants around metrics can fail or produce incomplete reports. The Memo metrics subsystem should be refactored so that metrics/counters are always available (enabled unconditionally) and can be queried without depending on internal implementation details of the core Memo engine.

When running Memo computations via Memo.run/Memo.exec and then querying metrics, the following must hold:

- Calling Memo.Metrics.assert_invariants () must succeed after typical Memo usage (creating memoized functions with Memo.create, executing them multiple times with repeated inputs and different inputs, and running nested dependencies).
- Calling Memo.Metrics.report ~reset_after_reporting:true must return a coherent report string and, when reset_after_reporting is true, subsequent reports should reflect that counters were reset (i.e., the report should not keep accumulating prior measurements after a reset).
- Memo metrics must be available without requiring an opt-in debug flag; using Memo should always collect the cheap counters needed for reporting.
- Existing Memo behavior must remain correct: repeated Memo.exec of the same memoized function on the same input should not recompute (i.e., should hit the cache), while running on a new input should recompute once and then be cached thereafter. Metrics collection must not break or change this caching behavior.

Additionally, dependency tracking for memoized computations should remain intact: after executing a memoized function, it must be possible (via Memo.For_tests.get_deps) to observe the dependencies recorded for a given (memo, input) pair, including dependency names and the inputs they were called with.

Fix Memo metrics/counters so the above behavior is satisfied, with cleaned-up/consistent naming and with metrics living outside the core memo implementation (so enabling metrics does not require touching or depending on core memo internals).