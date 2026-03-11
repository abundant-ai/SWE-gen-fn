Elixir should support an opt-in mode where module definitions are executed via the evaluator (interpreted) rather than via the compiler, without changing the resulting compiled artifact of the module’s functions.

Currently, when opting into interpreted module definitions through project compiler options (for example by setting `elixirc_options: [module_definition: :interpreted]`), module definition execution does not consistently behave as expected across tooling and evaluation contexts. In particular, defining a module and then immediately calling a function from that module in the same evaluation session must work reliably.

For example, evaluating code like:

```elixir
defmodule Sample do
  def foo, do: bar()
  def bar, do: 13
end && Sample.foo()
```

should evaluate successfully and yield `13`.

This interpreted module definition mode must be explicitly opt-in via compiler options, and must not change the generated `.beam` output semantics: functions inside the module are still compiled/optimized as usual; only the execution strategy for the module definition itself changes.

Error reporting must also remain high quality in this mode. When module definition evaluation fails (syntax errors, mismatched delimiters, incomplete expressions, etc.), the raised exceptions and formatted messages must still include correct file/line (and where available, column) information and should not regress formatting behavior (for example, ANSI formatting should not be incorrectly applied when an exception message already contains ANSI reset sequences).

Implement or adjust the module-definition execution pipeline so that:

- The `:module_definition` option (with value `:interpreted`) is recognized and changes module-definition execution accordingly.
- Defining modules in interactive/evaluation contexts and then invoking them immediately works correctly.
- Diagnostics (warnings) and exception metadata (file/line/column) produced during evaluation remain accurate and consistent with the existing behavior.
- Error messages in interactive contexts remain properly formatted and do not incorrectly prepend color codes in cases where the exception output already includes ANSI reset codes.