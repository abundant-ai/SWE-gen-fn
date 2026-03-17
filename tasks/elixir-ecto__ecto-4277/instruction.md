Calling `Ecto.Repo.delete/2` with the `:returning` option is currently not supported/propagated correctly, even though `insert/2` and `update/2` support `:returning`. This prevents users from requesting returned fields when deleting a struct and also prevents downstream consumers (such as telemetry handlers) from receiving returned values for deletes.

When a user executes a delete like:

```elixir
MyRepo.delete(%MySchema{...}, returning: true)
```

or requests specific fields via `returning: [...]`, the delete operation should pass the desired returning information through the Repo stack to the adapter layer in the same way as insert and update do. The adapter should receive the delete request along with the computed `returning` fields, and the Repo result should include those returned values (or at least correctly follow the established Repo contract for returning on write operations).

Expected behavior:
- `Ecto.Repo.delete/2` accepts the `:returning` option and does not ignore it.
- `returning: true` behaves consistently with other operations: it should translate to returning all schema fields that are eligible to be returned.
- `returning: [:field1, :field2, ...]` returns only those fields.
- The returning fields are correctly mapped to their database sources (for example, if a schema field uses `source: :yyy`, returning should request/represent the correct source field).
- The returned data should be placed on the deleted struct/result consistently with how `insert/2` and `update/2` expose returned fields.

Actual behavior:
- The `:returning` option on delete is not supported or not forwarded, so no returning fields are requested at the adapter level and no returned values are produced for delete operations.

Implement support for `:returning` in delete so it aligns with insert/update behavior and works end-to-end through `Ecto.Repo.delete/2` into the adapter callback invoked for deletes.