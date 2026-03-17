Empty-value handling in Ecto changesets is currently split across casting and required-field validation. In particular, `validate_required/2` performs extra pruning for “empty” inputs (notably strings that become empty after trimming), while `cast/4` also has its own empty-value logic. This leads to inconsistent behavior and makes it hard to customize what counts as “empty” in one place.

Unify empty-value pruning so that `cast/4` is responsible for removing/normalizing empty inputs, and `validate_required/2` no longer needs to perform special trimming-based emptiness checks.

Add support for functions in the `:empty_values` option used by casting. Today `:empty_values` supports literal values (for example `""` or `nil`), but it should also accept one or more functions that are invoked with the raw parameter value and return `true` if the value should be considered empty. This is required to support checks like “a string that becomes empty after trimming is empty”, but in a configurable way.

After this change:

- When calling `cast/4` with an `:empty_values` option that includes a function, parameters for permitted fields whose values satisfy that function must be treated as empty and pruned during casting (i.e., they should not end up as changes).
- `validate_required/2` should determine missing/empty required fields based on the result of casting (and the changeset data), without independently trimming strings to decide emptiness.
- The default behavior for empty values must remain compatible with current expectations, including treating blank/whitespace-only strings as empty via the default empty-values configuration.
- Provide/ensure a public helper `Ecto.Changeset.empty_values/1` that can be used to build on top of the defaults (for example, allowing users who previously passed a custom `:empty_values` list to extend the defaults rather than replace them).

Example of the expected behavior:

```elixir
params = %{"title" => "   "}
changeset = Ecto.Changeset.cast(%Post{}, params, [:title], empty_values: [fn v -> is_binary(v) and String.trim(v) == "" end])
# title should be treated as empty during cast; it should not be present as a change

changeset = Ecto.Changeset.validate_required(changeset, [:title])
# should report :title as required because casting pruned it as empty
```

Ensure `:empty_values` accepts combinations of literal empty markers and functions, and behaves consistently across different field types without raising errors when the function does not match (e.g., non-binary values).