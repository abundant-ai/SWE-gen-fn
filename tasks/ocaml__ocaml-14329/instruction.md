In the OCaml runtime’s major GC, work accounting for a GC cycle is inconsistent with what the pacing logic expects, which can both skew GC pacing decisions and surface correctness issues under stress with weak/ephemeron-heavy workloads.

Two user-visible problems need to be addressed:

1) Extra marking work performed during pointer updates is not being counted toward the current major GC cycle’s marking work. In particular, when a field update triggers additional marking via the runtime write barrier (e.g., through `caml_modify` calling into marking logic such as `caml_darken`), that extra marking work must be included in the “marking work” for the current major cycle. Without this, programs that do many no-op writes (writing the same value back) can cause major GC cycles to complete noticeably sooner than they should relative to runs that do not perform these writes.

Expected behavior: Repeatedly performing no-op writes should not materially change how quickly major GC cycles complete compared to an equivalent workload without those writes. When measuring `(Gc.quick_stat ()).major_collections` over a fixed amount of work, the difference between a run with writes and a run without writes should stay small (on the order of a couple collections at most), not diverge significantly.

Actual behavior: The run that performs no-op writes can complete major cycles faster/slower than the run without writes because the additional marking triggered by the write barrier is not charged to the cycle’s marking work, distorting pacing.

2) Sweeping work accounting incorrectly includes free blocks. Sweeping work is intended to approximate the size of allocated data that the sweeper must traverse (reachable or not). Free blocks should not contribute to sweeping work totals. Counting free blocks inflates sweeping work and makes pacing diverge from the intended model.

Additionally, under debug runtimes and multicore stress involving weak/ephemeron structures, the runtime can hit a reproducible assertion failure:

`Assertion failed: Has_status_val(v, status)`

This occurs during verification of ephemeron/weak lists (e.g., in logic analogous to `orph_ephe_list_verify_status`), suggesting that incorrect accounting/pacing can interact with ephemeron handling and major GC phase progression, exposing invariants violations.

The fix should ensure that:
- Any marking work performed indirectly by the write barrier (including darkening triggered by `caml_modify`) is counted toward the current major GC cycle’s marking work.
- Sweeping work does not count free blocks.
- With these accounting corrections, workloads that compare major collection counts with and without no-op writes should produce similar numbers of collections (no large drift), and the debug-runtime ephemeron/weak stress scenario should no longer trigger `Has_status_val(v, status)` assertion failures.