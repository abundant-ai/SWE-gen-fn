PostgREST fails to work correctly when database schema names contain uppercase letters or other characters that require quoting (e.g. spaces, quotes, punctuation). This is a regression compared to PostgREST v7.

A common failure mode is with computed columns: if a view/table is in a schema like "REST_api_v2_0" and there is a computed column function in that same schema (e.g. a function named thumbnail that takes the row type and returns a value), then requesting that computed column with a query like:

`GET /my_film?select=*,thumbnail`

returns an error similar to:

`column my_film.thumbnail does not exist`

The same database objects work when the schema is renamed to a lowercase, unquoted identifier (e.g. rest_api_v2_0), which indicates PostgREST is incorrectly handling schema-qualified identifiers when the schema requires quoting.

PostgREST should correctly support schema names that include uppercase characters, spaces, and other special characters, both for:

- resolving computed columns/functions that live in those schemas
- resolving functions accessible via the extra search path

In particular, function lookup and SQL generation must treat schema identifiers as case-sensitive and properly quoted when needed, so that functions in schemas like `"SPECIAL ""@/\#~_-"` can be found and invoked, and RPC calls to functions in such schemas work (for example calling a function like `special_extended_schema` via `GET /rpc/special_extended_schema?val=value` should succeed and return the expected result).

Additionally, schema names containing commas must be handled correctly as configuration values. If multiple schemas are accepted in configuration (e.g. a list), a comma inside an individual schema name should not make it impossible to specify that schema; configuration parsing should allow a schema name to include commas without misinterpreting it as a separator.

After the fix, requests that rely on computed columns and RPC/function resolution must behave the same regardless of whether schema names are lowercase or require quoting, and must no longer produce "column does not exist" errors solely due to schema name casing/special characters.