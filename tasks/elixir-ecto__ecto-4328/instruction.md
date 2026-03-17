Ecto currently lacks native support for variable-size bitstrings (where the number of bits is not a multiple of 8). As a result, attempting to use Elixir bitstring literals/values in queries does not consistently preserve their bitstring nature, and they cannot be reliably stored/queried as a dedicated database type (such as PostgreSQL’s bit/varbit).

When building queries, escaping a bitstring literal like `<<0, 1, 2>>` should produce an `Ecto.Query.Tagged` value that explicitly tags the value as a `:bitstring` (not merely `:binary`). The tagged type should reflect that the value is a bitstring and must not be coerced into a plain `:string` or `:binary` type.

Specifically, escaping a bitstring literal should result in an AST equivalent to tagging the value as `%Ecto.Query.Tagged{value: <<0, 1, 2>>, type: :bitstring}` (with appropriate runtime checks that distinguish binaries from non-byte-aligned bitstrings), so that downstream query compilation and adapters can handle it correctly.

Implement native bitstring support so that:
- Query escaping/tagging recognizes bitstring literals/values and assigns them the `:bitstring` Ecto type.
- The type is propagated through query building so expressions containing bitstrings are not mis-typed as `:binary`/`:string`.
- The behavior works for variable-size bitstrings (including those not divisible by 8 bits), so they can be stored and retrieved without loss or incorrect casting.

The expected behavior is that using bitstring values in queries preserves their type as `:bitstring` throughout query construction; the current behavior fails to provide a native `:bitstring` type/tagging and therefore cannot correctly represent variable-size bitstrings for database interaction.