Macro.escape/2 has a regression in Elixir 1.19.0-rc where the `unquote: true` option is not honored in some nested structures, particularly inside maps.

Currently, calling:

```elixir
Macro.escape(%{field: {:unquote, [], [:test]}}, unquote: true)
```

returns an escaped map where the `{:unquote, ..., ...}` tuple is treated as ordinary data and re-encoded into quoted tuple AST, producing something equivalent to:

```elixir
{:%{}, [], [field: {:{}, [], [:unquote, [], [:test]]}]}
```

Expected behavior (as in Elixir 1.18) is that with `unquote: true`, `{:unquote, meta, [expr]}` nodes encountered during escaping are actually unquoted, so the same call should produce:

```elixir
{:%{}, [], [field: :test]}
```

This should work not only for direct quoted expressions, but also when the quoted/unquote forms appear nested inside other data structures that Macro.escape/2 supports (including maps and their values). Ensure that `Macro.escape/2` consistently applies the `unquote: true` behavior while recursively escaping map contents, so that unquote forms inside maps are evaluated/unwrapped instead of being escaped as plain tuples.

In addition, preserve the existing expected behavior where `unquote: true` causes `quote(unquote: false, do: unquote(...))` contents to be unquoted during escape, including when those quoted fragments appear as values within maps (e.g., `%{foo: quote(unquote: false, do: unquote(1))}` should escape to an AST map whose `foo` value is `1`).