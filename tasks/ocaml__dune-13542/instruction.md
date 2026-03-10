Sandbox creation is not being reported as a proper sandbox trace event in the same way as other sandbox lifecycle events. When running a build that uses an always-on sandbox dependency (e.g., a rule with (deps (sandbox always)) and a trivial action), the trace output should include sandbox lifecycle events that are consistent in shape and timing with other events.

Currently, sandbox creation is either missing from the trace output or emitted in a different/incorrect format compared to other sandbox events, making it impossible to reliably observe sandbox creation via `dune trace`.

The sandbox event stream must include a "sandbox" category event named "create" when the sandbox directory is created, and a corresponding "sandbox" event named "destroy" when it is removed. Both events must include:
- `args.loc`: the rule location (formatted like `dune:1` for a rule on line 1)
- `args.dir`: the sandbox directory path under the build directory (e.g. `_build/.sandbox/<digest>`)

Example of the expected trace entries (timestamps/durations may exist but are not semantically important):

{
  "cat": "sandbox",
  "name": "create",
  "args": {
    "loc": "dune:1",
    "dir": "_build/.sandbox/<digest>"
  }
}
{
  "cat": "sandbox",
  "name": "destroy",
  "args": {
    "loc": "dune:1",
    "dir": "_build/.sandbox/<digest>"
  }
}

Implement/adjust sandbox creation tracing so that the create event is emitted through the same event mechanism and with the same argument conventions as the other sandbox events, ensuring both create and destroy are always present and consistently structured for sandboxed rules.