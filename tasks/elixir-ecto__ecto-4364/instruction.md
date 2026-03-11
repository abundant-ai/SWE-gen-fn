Querying an embedded schema currently fails late with a confusing database error. For example, calling `Ecto.Queryable.to_query(MyEmbeddedSchema)` (where `MyEmbeddedSchema` is defined via `embedded_schema`) can produce a Postgrex error like:

`(Postgrex.Error) ERROR 42P01 (undefined_table) relation "nil" does not exist`

This happens because embedded schemas do not have a database table/source, but the system still attempts to treat them as queryable and only errors once it reaches the adapter/database layer.

Instead, Ecto should fail early and clearly when an embedded schema module is used as a query source. When calling `Ecto.Queryable.to_query/1` with an embedded schema module, it must raise `Protocol.UndefinedError` with an error message indicating that `Ecto.Queryable` is not implemented for the given module because it is an embedded schema (for example, the message should include a phrase like "the given module is an embedded schema").

Expected behavior: embedded schema modules are not queryable; `Ecto.Queryable.to_query(EmbeddedSchemaModule)` raises `Protocol.UndefinedError` with a clear embedded-schema-specific explanation.

Actual behavior: attempting to query an embedded schema can proceed and eventually crash with a database error about a missing/undefined table (often referencing relation "nil").