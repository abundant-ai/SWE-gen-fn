When compiling code that pattern-matches on a value and binds a variable in a `case` clause, Elixir may incorrectly treat that variable as still possibly being `nil` even when `nil` has already been handled by a previous clause. This causes spurious warnings about calling functions on `nil` as if it were a module.

For example, compiling the following code currently emits an incorrect warning:

```elixir
defmodule Test do
  def default_format(data) do
    case String.Chars.impl_for(data) do
      nil -> inspect(data)
      mod -> mod.to_string(data)
    end
  end
end
```

Actual behavior: the compiler warns as if `mod` could be `nil`, producing a message like:

```
warning: nil.to_string/1 is undefined (module nil is not available or is yet to be defined)
...
mod -> mod.to_string(data)
```

Expected behavior: since the `nil` case is explicitly handled by the first clause (`nil -> ...`), the variable bound in the subsequent clause (`mod -> ...`) must be non-`nil` for that branch. The compiler should track type refinements across `case` clauses so that in the second clause `mod` is treated as “result of `String.Chars.impl_for(data)` excluding `nil`”. As a result, no undefined-module warning should be emitted for `mod.to_string(data)` in this scenario.

This refinement should apply generally to `case`/pattern matching: after earlier clauses match specific values (like `nil`), later catch-all bindings should reflect that those earlier matched values are excluded, so later expressions don’t get incorrect warnings stemming from impossible types.