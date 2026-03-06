Two regressions need to be fixed.

1) Spread embeds (`...`) produce incorrect results for embedded relationships

PostgREST supports “spread embeds” in the `select` parameter, where fields from an embedded relationship are “spread” onto the parent row using the `...<relation>(...)` syntax. This currently breaks or behaves incorrectly in several valid relationship scenarios.

When a client performs requests like:

- `GET /projects?select=id,...clients(client_name:name)`
- `GET /grandchild_entities?select=name,...child_entities(parent_name:name,...entities(grandparent_name:name))&limit=3`
- `GET /videogames?select=name,...computed_designers(designer_name:name)`
- `GET /grandchild_entities?select=name,child_entity:child_entities(name,...entities(parent_name:name))&limit=1`
- `GET /country?select=name,...capital(capital:name)`

PostgREST should return a flat JSON object per base row where the selected embedded fields appear at the top level under the requested aliases (e.g., `client_name`, `parent_name`, `grandparent_name`, `designer_name`, `capital`).

Expected behavior details:
- Many-to-one: spreading a related row should duplicate the related field value for each base row; if the relationship is missing, the spread field should be `null`.
- One-to-one: spreading should yield a single scalar field per base row.
- Nested spreads: a spread inside another spread should work (e.g., spreading `child_entities` while also spreading `entities` inside it), producing all requested fields on the base row with correct values.
- Spread inside a normal embed: spreading fields within a regular embedded object should place the spread field inside that embedded object (not at the top level), while still working correctly.
- Computed relationships: spread should work for computed relationships the same way as for table relationships.

Currently, at least one of these scenarios fails (wrong JSON shape, missing fields, incorrect null-handling, or incorrect join behavior). Fix the spread-embed handling so these requests return the correct JSON shape and values.

2) JWT secret loading from file/stdin has incorrect behavior in some configurations

PostgREST supports reading `PGRST_JWT_SECRET` from a file by prefixing the value with `@`, including reading from stdin via `@/dev/stdin`.

The following must work:
- If `PGRST_JWT_SECRET` is set to `@<path>`, PostgREST must read the secret bytes from that file and successfully authorize requests signed with the corresponding secret.
- If the file suffix indicates base64 content (e.g., `.b64`) and `PGRST_JWT_SECRET_IS_BASE64=true`, PostgREST must decode and use the decoded secret.
- If `PGRST_DB_CONFIG=false` and `PGRST_JWT_SECRET=@/dev/stdin`, PostgREST must read the secret from stdin and start successfully, allowing JWT-protected endpoints to be accessed with a valid JWT.
- If the effective JWT secret is shorter than the minimum allowed length, PostgREST must refuse to start, exit with status code 1, and log the exact error message: `The JWT secret must be at least 32 characters long.`

At the moment, one or more of these behaviors is broken/regressed in v13 (e.g., secret not being read correctly from `@...`, incorrect base64 handling, startup not failing with the correct error/log message for short secrets, or auth failing even when the secret is correctly provided). Fix JWT secret input handling so authorization succeeds when configured correctly and startup fails with the specified error when the secret is too short.