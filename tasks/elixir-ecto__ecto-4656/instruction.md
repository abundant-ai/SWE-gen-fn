When using `Ecto.Changeset.cast/3` with a schema field of type `:binary`, certain valid binary inputs are being treated as “empty” and therefore dropped from the changeset without any error. In particular, binaries that consist only of ASCII control characters (for example `<<9>>` tab, `<<10>>` newline, `<<13>>` carriage return) result in the field being cast as `nil` and omitted from `changeset.changes`, causing silent data loss.

Repro:

```elixir
changeset =
  %MySchema{}
  |> Ecto.Changeset.cast(%{binary_field: <<10>>}, [:binary_field])

Ecto.Changeset.get_field(changeset, :binary_field)
# expected: <<10>>
# actual: nil
```

Expected behavior: `:binary` fields should accept any valid binary, including binaries containing only control characters, and those values must be preserved in the changeset’s changes rather than being considered empty.

The root behavior to correct is Ecto’s “empty value” handling used during casting: default empty checks must take the field type into account so that `:binary` values like `<<9>>`, `<<10>>`, and `<<13>>` are not treated the same as empty strings/whitespace. At the same time, `cast/4` should allow users to provide an `:empty_values` entry that can include functions of arity 2 (e.g. `fn value, type -> ... end`) so callers can decide emptiness based on both the incoming value and the field type. This should work alongside existing empty value options (such as literals and 1-arity functions).

After the fix, casting a `:binary` field with `<<9>>`, `<<10>>`, or `<<13>>` should result in those exact binaries being present in `changeset.changes` and returned by `get_field/2`, with no errors added.