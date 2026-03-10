Dune’s tracing output for sandboxed actions is missing a dedicated event that records when the build system takes a snapshot of a sandbox for later promotion/patch-back behavior. This makes it impossible to observe (via `dune trace`) when sandbox snapshotting occurs, and some sandbox flows (notably `patch_back_source_tree`) require this signal to be emitted consistently.

When building rules that use sandboxing, `dune trace cat` should emit JSON events with `cat: "sandbox"` to describe key lifecycle points. The following sandbox events must be produced:

1) For a rule that declares sandboxing (e.g. `(deps (sandbox always))`) and runs an action, tracing must include a sandbox creation event and a sandbox destruction event:
- An event with `cat: "sandbox"`, `name: "create-sandbox"`, and `args` containing:
  - `loc`: the rule location (for example `"dune:1"`)
  - `dir`: `null` (for the create event)
- An event with `cat: "sandbox"`, `name: "destroy"`, and `args` containing:
  - `loc`: the rule location
  - `dir`: the sandbox directory path (for example `_build/.sandbox/<digest>`)

2) For rules using `(sandbox patch_back_source_tree)`, tracing must also emit a sandbox snapshot event whenever Dune snapshots the sandbox state for patch-back/promotion purposes:
- Emit an event with `cat: "sandbox"`, `name: "snapshot"`, and `args` containing:
  - `loc`: the rule location (e.g. `"dune:1"`)
  - `dir`: the sandbox directory path (e.g. `_build/.sandbox/<digest>`)

In scenarios where `patch_back_source_tree` runs and a dependency is modified inside the sandbox such that promotion will later copy changes back to the source tree, the `snapshot` event should appear (and may appear more than once in a single build when snapshotting occurs multiple times). The snapshot event’s `dir` must match the sandbox directory used for the action.

Currently, `dune trace` does not reliably include the `sandbox`/`snapshot` event (or does not include it with the required `cat`, `name`, and `args` fields), causing expected tracing output to be incomplete. Implement the missing sandbox snapshot tracing so that `dune trace cat` includes the `snapshot` events with the correct shape and arguments in builds that use `patch_back_source_tree`, while preserving the existing create/destroy sandbox lifecycle events.