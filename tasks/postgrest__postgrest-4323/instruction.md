When running a PostgREST instance that exposes multiple schemas, error responses and related messaging are currently too vague/inconsistent in several failure scenarios. Improve the error messages so that clients get clear, actionable feedback, and ensure the responses are stable and consistent.

In particular, when a client selects a schema via the profile headers and requests a resource:

1) If the selected schema is not among the exposed schemas, the server should respond with HTTP 406 and an error payload using code `PGRST106` with:
- `message`: `Invalid schema: <schema>`
- `details`: null
- `hint`: a human-readable list of which schemas are exposed (e.g. `Only the following schemas are exposed: v1, v2, SPECIAL "@/\\#~_-"`)

For example, requesting `/parents` with `Accept-Profile: unknown` should return:
```json
{
  "message": "Invalid schema: unknown",
  "code": "PGRST106",
  "details": null,
  "hint": "Only the following schemas are exposed: v1, v2, SPECIAL \"@/\\#~_-\""
}
```

2) If the selected schema is valid/exposed but the requested table does not exist in that schema, the server should return HTTP 404 with code `PGRST205` and the message must include the fully qualified table name (schema + table) and explicitly mention the schema cache.

For example, requesting `/another_table` with `Accept-Profile: v1` should return:
```json
{
  "code": "PGRST205",
  "details": null,
  "hint": null,
  "message": "Could not find the table 'v1.another_table' in the schema cache"
}
```

3) These improvements must also apply when schema names include uppercase letters and special characters. The error messages and hints must preserve the original schema names accurately (including necessary escaping/quoting) so users can reliably understand what value was rejected or accepted.

Overall, make error messages for schema selection and table lookup failures more informative and consistent, ensuring the correct HTTP status codes (`406` for invalid schema, `404` for missing table in a valid schema) and the exact error codes (`PGRST106`, `PGRST205`) are used with `details`/`hint` fields set as shown above.