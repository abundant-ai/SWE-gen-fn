Spread embedding currently behaves incorrectly when using the `...` syntax in `select=` to spread fields from an embedded to-one relationship into the parent row.

When a client requests a spread embed like:

- `GET /projects?select=id,...clients(client_name:name)`

the response should include `client_name` at the top level for each project row (with `null` when the relationship is missing), rather than nesting it under a `clients` object or mis-parsing the spread target. The same should work for deeper nesting, e.g.:

- `GET /grandchild_entities?select=name,...child_entities(parent_name:name,...entities(grandparent_name:name))&limit=3`

This should return rows where `parent_name` and `grandparent_name` are spread into the top-level object for each `grandchild_entities` row.

Spread embedding must also work when the spread is inside a normal (non-spread) embed, for example:

- `GET /grandchild_entities?select=name,child_entity:child_entities(name,...entities(parent_name:name))&limit=1`

This should produce a top-level `child_entity` object containing `name` plus the spread field `parent_name` (spread from `entities`) within that embedded object.

Spread embedding is only valid for to-one relationships (many-to-one or one-to-one). If the target relationship is not to-one, the request must fail with a 400 error using code `PGRST119` and the following semantics:

- `GET /clients?select=*,...projects(*)`

Expected error JSON must include:

- `code`: `PGRST119`
- `message`: `A spread operation on 'projects' is not possible`
- `details`: `'clients' and 'projects' do not form a many-to-one or one-to-one relationship`
- `hint`: `null`

Additionally, ambiguous embedding disambiguation must remain correct for regular (non-spread) embeds. When a request attempts to embed a resource where more than one relationship exists between the origin and target, the server should respond with `300 Multiple Choices` and code `PGRST201`, including a `details` array describing the candidate relationships and a `hint` telling the client to disambiguate using the `!` syntax (e.g. `big_projects!jobs`). The spread-embed fix must not break this ambiguity detection behavior.

In short: implement/correct parsing and planning of spread embeds so that `...relation(field_alias:field)` spreads fields into the correct object level, supports nesting (including spread-inside-embed), enforces to-one-only constraints with the specified `PGRST119` error, and does not regress ambiguous embed disambiguation behavior (`PGRST201`).