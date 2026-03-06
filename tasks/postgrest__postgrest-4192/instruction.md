A request using spread embedding syntax can generate invalid SQL when the spread embed contributes no projected columns, resulting in a PostgreSQL parse error.

Reproduction example:

```bash
curl 'http://localhost:3000/projects?select=*,...clients()'
```

Current behavior: the server responds with an error like:

```json
{"code":"42601","details":null,"hint":null,"message":"syntax error at or near \"FROM\""}
```

Expected behavior: spread embedding should not produce malformed SQL, even when the embed selection is empty (e.g., `...clients()` with no fields inside). The request should succeed (HTTP 200) and return a valid JSON response, with the spread embed effectively contributing nothing to the output rather than causing a SQL syntax error.

The spread embedding implementation should also continue to work in these scenarios:
- Spreading fields from a many-to-one relationship, e.g. `...clients(client_name:name)`.
- Nested spread embeds across multiple relationships, e.g. selecting from a resource with `...child_entities(...entities(...))`-style nesting.
- Spread embeds inside a normal (non-spread) embed.
- Spreading from a one-to-one relationship.

In all cases, the SQL generator for spread embeddings must ensure it never emits an empty/invalid projection fragment that leads to `FROM` being preceded by an empty select list component.