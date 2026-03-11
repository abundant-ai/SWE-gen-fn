Ecto.Repo needs to support a new public function `transact/2` that behaves like `transaction/2`, while `transaction/2` becomes soft-deprecated.

Currently, repository code only exposes `transaction/2` for running a function or an `Ecto.Multi` inside a database transaction. A new API `transact/2` must be added so callers can write `Repo.transact(fun_or_multi, opts \\ [])` and get the same return semantics as `Repo.transaction/2` for all supported inputs.

When calling `Repo.transact/2` with a zero-arity or one-arity function, it should execute the function inside a transaction and return:

- `{:ok, value}` when the function completes successfully
- `{:error, value}` when the function triggers a rollback (including via `Repo.rollback/1`)

When calling `Repo.transact/2` with an `Ecto.Multi`, it should run all multi operations inside a single transaction and return:

- `{:ok, changes}` when all operations succeed
- `{:error, failed_operation_name, failed_value, changes_so_far}` when an operation fails

`Repo.transact/2` must also accept the same options as `Repo.transaction/2` and pass them through consistently (for example options such as `:timeout`, and any adapter-specific transaction options).

In addition, `Repo.transaction/2` should remain available and continue to work exactly as before, but should emit a soft deprecation warning directing users to `Repo.transact/2` (without breaking existing code). Existing code that calls `Repo.transaction/2` with either a function or `Ecto.Multi` must continue to return the exact same tuples and error shapes as it did previously.

After implementing `Repo.transact/2` and soft-deprecating `Repo.transaction/2`, ensure the transaction behavior is consistent across:

- nesting transactions
- rollbacks initiated inside the transaction function
- `Ecto.Multi` success and failure cases (including preserving `changes_so_far` on failure)

The key issue to resolve is that `Repo.transact/2` does not exist (or does not mirror `transaction/2` semantics), and `transaction/2` is not soft-deprecated while preserving backwards-compatible behavior. Implement the new function and adjust the old one accordingly so callers can migrate without behavioral changes.