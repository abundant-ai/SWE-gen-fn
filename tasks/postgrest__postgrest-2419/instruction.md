PostgREST should support “computed relationships”: functions that behave like first-class relationships for resource embedding, rather than relying on implicit composite-type field notation.

Currently, if you create a PostgreSQL function that takes a single argument of a table row type (e.g. `projects`) and returns either a single row or a set of rows from another table, it cannot be used for embedding in the same way as foreign-key relationships. This prevents common embedding features such as selecting subsets of embedded columns, nesting, and using the same embedding syntax and query planning optimizations that normal relationships get. It also makes it impossible to use a virtual/computed relationship when its name clashes with an existing column name on the same resource, because field notation will always resolve to the real column.

Implement first-class computed relationships so that, after schema cache is loaded, eligible functions are detected and exposed as embeddable relationships.

A computed relationship is defined by a PostgreSQL function with these characteristics:
- It is callable “as a virtual column” from a source relation: it takes exactly one parameter whose type is the composite row type of the source relation.
- It returns a relation-like result that can be embedded:
  - If it returns a single row (e.g. a composite type corresponding to a table/view row), it must behave as a many-to-one relationship in JSON output (embedded object).
  - If it returns multiple rows (SETOF), it must behave as a one-to-many relationship in JSON output (embedded array).

Required HTTP/query behavior:
- Embedding must work using the same `select=` syntax used for foreign-key embedding, but with an explicit function call form. Example requests that must work:
  - `GET /videogames?select=name,designers:computed_designers(name)` must return each videogame with an embedded `designers` object containing at least the selected fields (e.g. `{"name":"Sid Meier"}`).
  - `GET /designers?select=name,videogames:computed_videogames(name)` must return each designer with an embedded `videogames` array of objects.
- Computed relationships must support join modifiers and filtering like normal embeds:
  - `!inner` must filter the parent rows based on the embedded relationship.
  - `Prefer: count=exact` must still return correct `Content-Range` for these queries.
  - Example patterns that must work:
    - `GET /designers?select=name,videogames:computed_videogames!inner(name)&videogames.name=eq.Civilization%20I` should only return designers having a matching embedded videogame, and must include an accurate `Content-Range`.
    - `GET /videogames?select=name,designer:computed_designers!inner(name)&designer.name=like.*Hironobu*` should only return matching videogames and an accurate `Content-Range`.
- Computed relationships must work when the source resource comes from RPC endpoints as well (set-returning functions exposed under `/rpc/...`). For example:
  - `GET /rpc/getallvideogames?select=name,designer:computed_designers(name)` must embed the computed designer per returned videogame row.
  - `GET /rpc/getalldesigners?select=name,videogames:computed_videogames(name)` must embed videogames per returned designer row.
- Computed relationships must work with mutations (inserts/updates) in the same way normal relationships do, including returning embedded computed relationships when requested via `select=`.

Relationship resolution and overrides:
- When both a computed relationship and a detected relationship (e.g. FK-based) could exist for the same pair of resources, the system must have deterministic behavior and support overriding the automatically detected relationship with the computed one (or vice versa) based on configured/declared precedence used by PostgREST relationship resolution.
- Self relationships (computed relationships where source and target are the same table) must be supported without ambiguity.

Name resolution:
- A computed relationship must be callable even if its name clashes with an existing column on the source relation. The explicit computed relationship call syntax (e.g. `alias:computed_fn(col)`) must resolve to the computed relationship rather than the real column.

In summary, functions matching the computed-relationship shape must be introspected into the schema cache as relationships and then participate in embedding, inner joins, filtering, counting, RPC-originated resources, and mutation-return embeddings just like foreign-key-based relationships.