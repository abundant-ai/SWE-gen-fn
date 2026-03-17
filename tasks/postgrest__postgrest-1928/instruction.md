OpenAPI schema generation does not correctly include PostgreSQL column default values for string-typed columns, and it can misclassify some PostgreSQL types in a way that prevents defaults from being represented with the correct OpenAPI type.

Reproduction: create a table with a column default, e.g. `CREATE TABLE t (i int DEFAULT 42)` or a text/varchar column with a string default. Request the OpenAPI document (e.g. with `Accept: application/openapi+json`). The resulting OpenAPI schema for the table’s columns should include the `default` field for columns that have a server-side default.

Actual behavior: the OpenAPI output omits the `default` value for some columns, particularly when the column is a string type. In addition, some PostgreSQL array types are represented as OpenAPI `type: "string"` instead of `type: "array"`, which can also lead to incorrect schema/default representation.

Expected behavior: when PostgREST generates an OpenAPI schema for a table/view, it should detect column defaults from PostgreSQL and include them in the corresponding OpenAPI Schema Object as `default`, with the JSON value conforming to the declared OpenAPI type (for example, string defaults must be emitted as JSON strings, numeric defaults as numbers, boolean defaults as booleans). For PostgreSQL string-like types, PostgREST should recognize common string formats and still emit a proper OpenAPI string schema that can carry a `default` value, while explicitly not treating `json`/`jsonb` columns as string formats. For PostgreSQL array-typed columns, the OpenAPI schema should be emitted as `type: "array"` (with appropriate `items` typing) rather than `type: "string"`.

The bug is resolved when:
- OpenAPI output includes `default` for columns with defaults, including string defaults.
- String type detection covers most string formats but does not categorize `json` and `jsonb` as string formats.
- Array columns are represented as OpenAPI arrays, not strings, and defaults (when present) are compatible with the emitted type.