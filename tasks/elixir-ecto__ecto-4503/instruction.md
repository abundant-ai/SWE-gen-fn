Preload queries cannot currently be distinguished from other read queries in a consistent way that supports multi-tenancy filtering with foreign keys. In particular, when a repository automatically injects tenant scoping (for example, adding an `org_id` constraint to all read operations), the queries issued internally to load associations via `preload` need to be identifiable so they can be treated differently (e.g., filtered out or handled with special scoping rules). Right now there is no dedicated query tag indicating that a query is being executed as part of a preload.

Add support for an `ecto_query: :preload` option on the queries used to load preloads, so that any repository-level logic that inspects query options can reliably detect association preload reads.

Concretely, when preloading associations (including nested preloads), the internal query execution should carry an option `ecto_query: :preload`. This option must be present in the options visible to repo callbacks/telemetry/logging and any query preparation layer that receives the repo options for execution.

Additionally, schema migration reads should be tagged using the same mechanism: update migration-related operations so that they pass `ecto_query: :schema_migration` (instead of using a boolean option like `schema_migration: true`). Existing behavior that depends on identifying schema migration queries should continue to work, but now via `ecto_query`.

Expected behavior examples:

1) When calling `Repo.preload(struct_or_structs, preloads, opts)`, all SQL queries issued to load associations must include `ecto_query: :preload` in the execution options.

2) When running schema migration operations that read/write the schema migrations table, the execution options must include `ecto_query: :schema_migration`.

Actual behavior (current): preload queries are not tagged with `ecto_query: :preload`, and migration operations use an option like `schema_migration: true` instead of a unified `ecto_query` tag, making it difficult to filter/handle these operations consistently in multi-tenant setups.