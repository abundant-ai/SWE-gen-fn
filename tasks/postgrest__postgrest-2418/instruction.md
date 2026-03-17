PostgREST’s behavior when the PostgreSQL `pg-safeupdate` extension is enabled/disabled needs to be correct for full-table UPDATE/DELETE requests (requests without any filtering condition).

When `pg-safeupdate` is enabled, a full-table DELETE must be blocked by the database and PostgREST must surface this as an HTTP 400 with a JSON error payload containing:

```json
{
  "code": "21000",
  "details": null,
  "hint": null,
  "message": "DELETE requires a WHERE clause"
}
```

At the same time, a full-table UPDATE via PATCH without any condition must not update anything and must not raise an error; instead it should behave like updating an empty set: return HTTP 404 with an empty body, no `Content-Type` header, and `Content-Range: */0` when the client sends `Prefer: count=exact`.

When `pg-safeupdate` is disabled, a full-table DELETE without any condition should be allowed and must delete all rows. In that case, the response must be HTTP 204 with an empty body, no `Content-Type` header, and `Content-Range: */3` when the client sends `Prefer: count=exact` (assuming 3 rows existed).

Also, when a filter is present (e.g. `DELETE /safe_delete?id=gt.0`), DELETE must be allowed even with `pg-safeupdate` enabled, returning HTTP 204 with empty body, no `Content-Type`, and `Content-Range: */3` when `Prefer: count=exact` is used.

In summary, ensure PostgREST correctly distinguishes “no condition present” from “condition present” for DELETE, properly propagates the `pg-safeupdate` error as a 400 with the expected JSON structure, and preserves the expected status codes and headers for these scenarios (including correct `Content-Range` behavior under `Prefer: count=exact`).