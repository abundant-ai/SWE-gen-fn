Dynamic code evaluation in Elixir currently relies on the application compile-time environment key `:elixir, :dbg_callback` to decide how `dbg/2` expands/behaves during compilation. Because this setting is marked as compile-time, changing it at runtime (for example with `Application.put_env(:elixir, :dbg_callback, ...)`) can cause Mix to fail with a compile environment mismatch when recompiling in an interactive session.

A concrete failure occurs when a dependency (such as Kino) sets a runtime `:dbg_callback` different from the one Elixir was compiled with. After calling code that uses `dbg/2`, attempting to recompile in IEx (for example via `recompile/0`) raises:

```
** (Mix.Error) the application :elixir has a different value set for key :dbg_callback during runtime compared to compile time.

  * Compile time value was set to: {Macro, :dbg, []}
  * Runtime value was set to: {Kino.Debug, :dbg, [{Macro, :dbg, []}]}
```

Dynamic evaluation should allow callers to override `dbg/2` behavior for the evaluated code without mutating the application environment.

Implement support for a new `:dbg_callback` option on the `Code.eval_*` family so that `dbg/2` inside dynamically evaluated code uses the callback specified for that evaluation only. This option must be supported by the evaluation APIs that accept options, including:

- `Code.eval_string/3`
- `Code.eval_quoted/3`
- `Code.eval_file/2` (and any other public `eval_*` variants that accept an options keyword list)

Expected behavior:

- Passing `dbg_callback: {mod, fun, extra_args}` (or the same callback form accepted by `:elixir, :dbg_callback`) to an eval function should cause `dbg/2` inside the evaluated code to invoke that callback for that evaluation.
- The override must be scoped to the evaluation/compilation of the provided string/quoted/file and must not require (or be implemented by) changing `Application.put_env(:elixir, :dbg_callback, ...)`.
- Using these eval functions with `dbg_callback` should avoid triggering Mix’s compile-env validation error described above when recompiling in IEx.

Additionally, fix the inconsistency where `:prune_binding` behavior/documentation for `Code.eval_string/3` and `Code.eval_quoted/3` is incorrect: these functions should correctly support the `:prune_binding` option (or, if they do support it already, ensure the behavior matches the documented/expected semantics), so that bindings can be pruned as requested when evaluating code dynamically.