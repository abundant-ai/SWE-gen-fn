Ecto’s query DSL currently only accepts literal atoms as the alias name in `selected_as/1` and `selected_as/2`. This prevents building queries where the alias name is provided dynamically via interpolation (pin operator), even when the interpolated value is an atom.

When writing queries that reference a previously selected alias in other clauses (such as `group_by` or `order_by`), users should be able to write:

```elixir
key = :ident
from p in "posts",
  select: selected_as(p.id, :ident),
  group_by: selected_as(^key)
```

Expected behavior: if the interpolated value is an atom, `selected_as(^key)` should compile and produce the same query expression as `selected_as(:ident)`. This should work consistently anywhere `selected_as/1` is accepted (for example, in `group_by` and `order_by`).

Actual behavior: interpolated names are rejected (or not handled) as alias names, even when they are atoms.

Additionally, error reporting should be precise and consistent:

1) Compile-time validation for `selected_as/1` should accept either a literal atom or an interpolated value. If a non-atom literal is given, compilation must raise `Ecto.Query.CompileError` with:

```
expected literal atom or interpolated value in selected_as/1, got: `"ident"`
```

2) Runtime validation for interpolated values in `selected_as/1` must ensure the interpolated value is an atom. If a non-atom value is interpolated (for example `^"ident"`), compilation must raise `Ecto.Query.CompileError` with:

```
expected atom in selected_as/1, got: `"ident"`
```

Implement support for interpolated alias names so that `selected_as/1` (and corresponding usage patterns that rely on it, such as in `group_by`/`order_by`) works with `^atom` while still rejecting non-atom values with the exact messages above.