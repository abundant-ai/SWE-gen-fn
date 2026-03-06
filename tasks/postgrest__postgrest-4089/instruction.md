When a client selects an invalid schema via the schema-selection request header (e.g., `Accept-Profile`), PostgREST returns a 406 error. Currently, the error response includes a list of all exposed schemas, even if the current database role does not have `USAGE` privilege on some of those schemas. This leaks schema names that are not accessible to the caller.

Reproduction example:

```bash
curl 'http://localhost:3000/todos' -H 'Accept-Profile: wrong'
```

If `wrong` is not a valid/allowed schema for the current role, the response should be a 406 with code `PGRST106`. The response must:

- Put the invalid schema value into the `message` field, in the form `"Invalid schema: <schema>"` (for example, `"Invalid schema: unknown"`).
- Avoid listing schema options in `message`.
- Include the list of exposed schemas in the `hint` field, but only those schemas that are both exposed by configuration and usable by the current role (i.e., the role has `USAGE` privilege on the schema).

Expected shape for an invalid schema `unknown` (order and formatting should match the existing style):

```json
{
  "message": "Invalid schema: unknown",
  "code": "PGRST106",
  "details": null,
  "hint": "Only the following schemas are exposed: v1, v2, SPECIAL \"@/\\#~_-"
}
```

If a schema is exposed by configuration but the current role lacks `USAGE` on it, it must not appear in the `hint` list.

This must work consistently for schema names containing uppercase letters and special characters; the invalid schema should be echoed back exactly as received, and the exposed-schema list should preserve the existing escaping/quoting behavior for special names.

Implement the necessary role-aware filtering so that schema visibility in this error is computed per-request/per-role rather than using a role-agnostic list of exposed schemas.