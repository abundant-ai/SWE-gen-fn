Dune’s tracing currently emits a sandbox lifecycle event when a sandbox is created, but it does not emit any corresponding event when the sandbox is destroyed/cleaned up. This makes it impossible to correlate sandbox creation with cleanup in trace output.

When building a rule that uses a sandbox (e.g., a rule with `(deps (sandbox always))`), `dune trace cat` should include sandbox-category events for both sandbox creation and sandbox destruction.

Expected behavior:
- A trace event in category `sandbox` with name `create-sandbox` is emitted when a sandbox is created.
- A second trace event in category `sandbox` with name `destroy` is emitted when the sandbox directory is destroyed/removed.
- Both events must include an `args` object with:
  - `loc`: the rule location string (e.g. `"dune:1"`)
  - `dir`:
    - `null` for `create-sandbox` (since the final directory may not be known/meaningful at that point)
    - the sandbox directory path for `destroy` (e.g. `_build/.sandbox/<digest>`)

Actual behavior:
- Only `create-sandbox` is emitted; no `destroy` event is present in the trace output even though the sandbox directory is removed.

Implement sandbox destruction tracing so that whenever Dune tears down a sandbox directory as part of executing a sandboxed action, it emits the `sandbox`/`destroy` trace event with the correct `loc` and `dir` fields. The event should appear in the trace stream alongside other sandbox events and be produced reliably for sandboxed builds.