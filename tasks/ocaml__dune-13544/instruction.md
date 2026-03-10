When running a build rule that uses sandboxing, Dune emits trace events in the "sandbox" category for sandbox lifecycle steps. Currently, only "create" and "destroy" are emitted, but there is no event emitted when the sandbox contents are extracted back to the build directory.

Add support for a new trace event named "extract" in the "sandbox" category.

Expected behavior:
- For a sandboxed rule (e.g., a rule with deps containing `(sandbox always)`), `dune build` should produce three sandbox trace events in order: `create`, `extract`, `destroy`.
- Each of these events must include the same arguments shape:
  - `loc`: a location string pointing to the rule location (e.g., `"dune:1"`)
  - `dir`: the sandbox directory path (e.g., `"_build/.sandbox/<digest>"`)
- The new `extract` event must be emitted at the time Dune copies/extracts outputs from the sandbox back to the normal build context (i.e., not at creation time and not at final cleanup).

Actual behavior:
- Only `create` and `destroy` events are visible under the "sandbox" category; there is no `extract` event, so trace consumers cannot determine when the extraction step happened.

Reproduction example:
- Create a rule on an alias that forces sandboxing and runs a trivial action.
- Run `dune build @<alias>` and inspect the trace stream (e.g., via `dune trace cat` filtered to `.cat == "sandbox"`). You should see a `create` event and a `destroy` event today; after the fix, you must also see an `extract` event between them with matching `loc` and `dir` fields.