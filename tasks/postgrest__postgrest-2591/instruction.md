When requesting the generated OpenAPI document (e.g., with an `Accept: application/openapi+json` header), PostgREST emits schemas for PostgreSQL array-typed fields/parameters using `type: string` combined with `format: ARRAY`. This is not the correct OpenAPI representation for arrays and causes generated clients (e.g., via openapi-generator) to treat array results as strings.

The OpenAPI output must represent array-typed values using `type: "array"` and must include an `items` schema describing the element type of the array. For example, if a database column/parameter is an array of text, the schema should be:

```json
{ "type": "array", "items": { "type": "string" } }
```

Instead of something like:

```json
{ "type": "string", "format": "ARRAY" }
```

This needs to work generally for array-valued types appearing in the OpenAPI spec (including table columns and function/procedure parameters/return shapes wherever PostgREST exposes types in the spec). The element type must match the underlying PostgreSQL base type (e.g., `_int4`/`int4[]` should map to integer items, `text[]` to string items, etc.), and the emitted schema must be valid OpenAPI JSON.

Reproduction: create/expose a resource that returns or accepts a PostgreSQL array type, then fetch the OpenAPI JSON. The schema for that field/parameter currently declares it as a string with `format: ARRAY`; it should instead declare `type: array` with an `items` schema matching the array element type.

Expected behavior: OpenAPI schemas for PostgreSQL array types use OpenAPI-native arrays (`type: array`) and always include `items` with the correct item type.

Actual behavior: array types are emitted as `type: string` with `format: ARRAY`, with no `items`, leading clients to parse arrays incorrectly.