The Elixir compiler/type checker can hang or take exponential time when compiling functions with many clauses that pattern match on maps with different key sets, especially when some clauses bind the map and later access keys that weren’t in that clause’s match.

For example, a module that defines many clauses like:

```elixir
# Clause set A: matches on %{status: ...}
def process(%{status: :pending}, _opts), do: {:ok, "Pending"}
def process(%{status: :completed}, _opts), do: {:ok, "Completed"}

# Clause set B: matches on %{category: ..., kind: ...} but later accesses data.status

def process(%{category: :alpha, kind: :primary} = data, opts) do
  with {:ok, ctx} <- context(opts[:context]), do: format(:alpha, data.status, ctx)
end

# ...many more similar clauses (20+ total)
```

may cause compilation to appear to hang indefinitely (or take extremely long) on recent Erlang/OTP and Elixir versions.

The compiler’s internal representation/handling of map fields during type checking (including operations that compute unions, intersections, and differences of map key sets across clauses) should not exhibit exponential blow-ups as the number of clauses grows and as key sets vary between clauses.

Fix the compiler/type-checking logic so that compiling modules with many function clauses that pattern match on different map key sets completes in reasonable time and does not hang. The behavior should remain correct: the compiler must still correctly infer/track map field information across clauses, including cases where a clause pattern matches on one set of keys but later code accesses additional keys on the bound map.

This should be addressed by improving how map fields are normalized/represented internally so key-set operations used by the type checker do not degrade catastrophically with many clauses.