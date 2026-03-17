When generating the OpenAPI spec, the server has an “ignore privileges” mode intended to include tables/functions even if the current role lacks permissions. However, in this mode the OpenAPI output is not being filtered by the schema requested via the `Accept-Profile` header.

Reproduction scenario:
- Configure OpenAPI mode to ignore privileges.
- Request the OpenAPI document (e.g., `GET /` with `Accept: application/openapi+json`).
- When the database contains objects in multiple schemas, sending `Accept-Profile: <schema>` should restrict the OpenAPI `paths` to objects belonging to that schema (and any always-included schemas per normal profile behavior).

Actual behavior:
- In ignore-privileges mode, the OpenAPI output does not properly honor `Accept-Profile`. Objects from other schemas are not included/excluded correctly; for example, endpoints for tables/functions that exist only in a non-default schema may remain missing even when `Accept-Profile` targets that schema.

Expected behavior:
- “Ignore privileges” should only bypass privilege/ACL checks; it must still apply schema/profile filtering based on `Accept-Profile`.
- Without `Accept-Profile`, the OpenAPI spec should not include endpoints from non-selected schemas.
- With `Accept-Profile: v1` (or another schema name), the OpenAPI spec should include endpoints for tables and RPC functions that belong to that schema.

Additionally, the configuration values for `openapi-mode` have been renamed for clarity:
- `follow-acl` must be replaced by `follow-privileges`
- `ignore-acl` must be replaced by `ignore-privileges`

The server should accept and correctly apply the new `openapi-mode` values, and defaults/config rendering should reflect the new names (e.g., the default should be `follow-privileges`). If invalid/old values are provided, behavior should be defined consistently with the project’s config validation rules (e.g., reject with a clear error or map to the new names if backward-compatibility is intended).