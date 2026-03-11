Using `splice/1` inside `fragment/1` currently fails to recognize query binding aliases (such as `seq` in `from seq in ...`) when the spliced expression list contains references to those bindings. This makes it impossible to build reusable macros that splice fragments while still allowing callers to pass binding-based expressions.

Reproduction:

```elixir
import Ecto.Query

from seq in "pg_class",
  where: seq.relkind == "S",
  select: %{
    seq_name: fragment("concat_ws(?, ?)", ".", splice(^["public", seq.relname]))
  }
```

Actual behavior: compilation fails with an undefined variable error for the query binding, e.g.

```text
error: undefined variable "seq"
** (CompileError) cannot compile code (errors have been logged)
```

Expected behavior: query binding aliases referenced inside the list passed to `splice/1` should be correctly expanded and resolved, the same way they are when used directly in `fragment/1` arguments (without splicing) or other query expressions.

A common use case is defining a macro that wraps `fragment/1` and uses `splice/1` to accept a list of expressions:

```elixir
defmacro concat_ws(separator, expressions) do
  quote bind_quoted: [separator: separator, expressions: expressions] do
    fragment("concat_ws(?, ?)", separator, splice(^expressions))
  end
end
```

This macro should be usable as:

```elixir
from seq in "pg_class",
  select: %{seq_name: concat_ws(".", ["public", seq.relname])}
```

and compile successfully, preserving correct binding resolution for `seq.relname` and other binding-based expressions within the spliced list.

Implement support for compile-time fragment splicing such that `splice/1` can accept interpolated lists containing query binding references, and those references are expanded into the correct query expression AST during query compilation/planning (rather than raising undefined variable compile errors).