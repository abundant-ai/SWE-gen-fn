When creating or updating maps using Elixir’s map syntax (`%{...}` and `%{map | ...}`), the compiler should track “domain keys” (the set of atom keys known to exist in the map) and preserve/propagate that information through compilation artifacts that rely on it (notably type/signature inference and protocol-related metadata).

Currently, map literals and map updates built with the map syntax do not reliably record which atom keys are known to be present after the operation, especially when mixing known atom keys with dynamic/unknown keys. This causes downstream consumers of compiler/type metadata to treat maps as having unknown or overly broad key domains, leading to incorrect inferred map/struct shapes.

The behavior needs to be corrected so that:

- Map creation with atom keys via map syntax preserves a known key domain. For example, compiling code like:

  ```elixir
  def map_create_with_atom_keys(x) do
    %{__struct__: A, x: x, y: nil, z: nil}
    x
  end
  ```

  should result in metadata/type information that reflects that the map has known atom keys `:__struct__`, `:x`, `:y`, and `:z` (and not an “unknown keys” domain).

- Map updates with atom keys via update syntax keep and update the known key domain. For example:

  ```elixir
  def map_update_with_atom_keys(x) do
    %{x | y: nil}
    x
  end
  ```

  should preserve that `x` is a map with a known set of atom keys and that `:y` is among them after the update.

- Map updates that introduce a dynamic key must widen the key domain appropriately. For example:

  ```elixir
  def map_update_with_unknown_keys(x, key) do
    %{x | key => 123}
    x
  end
  ```

  must be treated as updating with an unknown key, so the resulting key domain cannot remain “only known atom keys”; it must reflect that arbitrary keys may be present/updated.

- Struct creation/update patterns that depend on known keys should continue to work with the improved tracking. For instance, code that pattern matches on a struct/map shape like:

  ```elixir
  defp infer(%A{x: <<_::binary>>, y: nil}) do
    :ok
  end
  ```

  should be able to rely on correct inferred key domains from `%A{...}` creation as well as `%{__struct__: A, ...}` map construction.

If this domain-key tracking is missing or incorrect, compilation-time metadata used for inferred map types/signatures will not match the actual map operations performed by the code, and consumers reading those inferred signatures will see incorrect shapes (for example, losing knowledge of specific atom keys on map creation/update).

Implement the necessary changes so that domain keys are tracked consistently for map creation and map update expressions using map syntax, and ensure this information is reflected in the relevant compilation/type metadata produced for modules.