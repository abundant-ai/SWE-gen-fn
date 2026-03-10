PostgREST’s resource embedding currently represents certain relationships as a single JSON object when it detects a one-to-one relationship. This behavior was introduced in v10.0.0 as part of one-to-one relationship detection and changed the JSON shape returned by embedding compared to v9.0.1, where these embeddings were represented as an array with a single element. This makes upgrades difficult for projects that relied on the old array-shaped embeddings.

Add a configuration option that controls which relationship types are embedded as a single JSON object (instead of an array). The option name is:

`db-resource-embedding-single`

It must accept a comma-separated list of relationship kinds. The supported values are:

- `many-to-one`
- `one-to-one`

Default behavior must embed both many-to-one and one-to-one relationships as a single JSON object:

`db-resource-embedding-single = "many-to-one, one-to-one"`

If a project sets:

`db-resource-embedding-single = "many-to-one"`

then one-to-one relationships must no longer be embedded as a single object; instead they must be embedded using the array form (even if the relationship is detected as one-to-one). This is to preserve v9.0.1-style output for one-to-one cases while keeping many-to-one as single-object.

One-to-one relationship detection must work when a foreign key implies uniqueness on the referencing side, including at least these cases:

1) The foreign key columns are also the (composite) primary key of the referencing table.
2) The foreign key columns have a UNIQUE constraint.

When one-to-one embedding as single-object is enabled (default), embedded output should be an object (or null when missing), not an array with one element. This must apply consistently for:

- regular table and view reads using resource embedding via `select=...` with rename syntax (e.g. `designer:...`)
- RPC responses when using `select` with embedded relationships
- mutation responses (e.g. when `Prefer: return=representation` is used) where embedded relationships are included
- cases using `!inner` joins in embedded selects, and interactions with `Prefer: count=exact` (counts/Content-Range must remain correct while embedding shape follows the configured rule)

Computed relationships must be able to override relationship behavior as they do today; introducing one-to-one detection must not create new relationship disambiguation conflicts. One-to-one should be treated as a refinement of many-to-one (i.e., it should not create an additional distinct relationship that changes naming/disambiguation rules), but it should affect embedding shape when enabled.

The bug to fix is that there is currently no way to opt out of one-to-one single-object embedding, which forces a breaking response shape change on upgrade. Implement the configuration and ensure responses follow the configured embedding shape rules in all the scenarios above.