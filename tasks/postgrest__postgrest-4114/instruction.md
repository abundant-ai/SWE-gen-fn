After upgrading to PostgREST v13.0.0, GET requests that combine an ORDER BY with explicit NULLS FIRST/NULLS LAST and pagination started failing with a SQL syntax error. This is a regression: the same requests worked in v12.2.12.

Reproduction example:

- Request: `GET /country?order=headofstate.desc.nullslast&limit=10`
- Actual response: HTTP 400 BadRequest with a PostgreSQL error payload similar to:

```json
{
  "code": "42601",
  "details": null,
  "hint": null,
  "message": "syntax error at or near \"NULLS\""
}
```

Observed behavior details:
- If the `.nullslast` (or `.nullsfirst`) modifier is removed, pagination works.
- If `limit`/`offset` is removed, the order modifier works.
- The failure occurs specifically when both features are used together, indicating the generated SQL is malformed (typically due to `NULLS FIRST/LAST` being emitted in the wrong position relative to LIMIT/OFFSET or otherwise attached to the wrong SQL fragment).

Expected behavior:
- Requests using `order=<col>.(asc|desc).(nullsfirst|nullslast)` must work correctly together with `limit` and `offset`.
- The server should generate valid SQL where `NULLS FIRST`/`NULLS LAST` is part of the `ORDER BY` item and the pagination (`LIMIT`/`OFFSET`) appears after the full `ORDER BY` clause.
- The endpoint should return HTTP 200 with the expected ordered, paginated results rather than a 400.

Implement a fix in the request planning / query building pipeline so that combining ordering nulls modifiers with pagination no longer produces invalid SQL, and ensure the behavior is covered so this regression does not reappear.