Error messages and logs that include Ecto types currently format parameterized types by calling `inspect(type_term)`. For parameterized types, this produces very noisy output because the type term contains the full parameter map. For example, when an `Ecto.Enum` field receives an invalid value, the raised `Ecto.ChangeError` currently includes a type snippet like `{:parameterized, Ecto.Enum, %{...large param map...}}`, which is hard to read.

Introduce support for an optional `format/1` callback on `Ecto.ParameterizedType` modules, and make Ecto use it whenever it needs to format a type for injection into errors and other logs.

The behavior should be:

When formatting a parameterized type term of the form `{:parameterized, module, params}` via `Ecto.Type.format/1`, if `module` implements `format/1`, Ecto must call `module.format(params)` and use the returned string. If the module does not implement `format/1`, formatting must fall back to the old behavior (equivalent to `inspect(type_term)`).

This formatting must also apply when parameterized types appear inside composite types. For example, formatting `{:array, {:parameterized, Ecto.Enum, params}}` should produce something like `{:array, #Ecto.Enum<values: [:read, :create, :update]>}` (i.e., the inner parameterized type uses the custom formatter).

`Ecto.Enum` must implement this new callback so that, for a schema field like `field :role, Ecto.Enum, values: [:admin, :editor]`, error messages that previously ended with `does not match type {:parameterized, Ecto.Enum, %{...}}` instead end with a concise representation like `does not match type #Ecto.Enum<values: [:admin, :editor]>`.

In addition, `Ecto.Type.format/1` must support formatting of parameterized types directly, so that calling `Ecto.Type.format({:parameterized, SomeParameterizedType, params})` uses `SomeParameterizedType.format(params)` when available and otherwise falls back to inspecting the type term.

A minimal example that must work:

```elixir
# Given a parameterized type module that defines:
#   def format(:format), do: "#MyParameterizedType<:format>"

Ecto.Type.format({:parameterized, MyParameterizedType, :format})
# => "#MyParameterizedType<:format>"
```

Existing type operations (e.g., `Ecto.Type.type/1`, `cast`, `dump`, `load`, `embed_as`, etc.) must continue to behave as before; the change is specifically about how types are formatted for display in errors/log output.