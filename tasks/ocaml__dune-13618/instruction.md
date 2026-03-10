Dune’s trace output is missing useful details for actions that create or overwrite files. When a build rule performs a file-writing action (for example, an action equivalent to “write-file <path> <contents>”), `dune trace cat` should emit a trace event for that action that includes information about the file that was written.

Currently, trace events for the write-file action do not include (or do not reliably include) the written file’s path and size, making it impossible to attribute produced artifacts to file-writing actions via the trace stream.

Update the trace event emission for the write-file action so that the emitted event contains an `args` object including:

- `file`: the build path of the file that was written (as it appears in the build output location, e.g. under `_build/<context>/...`). This should point to the actual produced file location, not the source-tree-relative target name.
- `size`: the size in bytes of the contents written to the file.

Example of the expected trace payload for a write-file action writing "hello" to a target named `trace-file.txt`:

```json
{
  "file": "_build/default/trace-file.txt",
  "size": 5
}
```

The event should be associated with the action category/name for the write-file action so that querying the trace stream for action events named `write-file` returns these `file` and `size` arguments for the relevant outputs.