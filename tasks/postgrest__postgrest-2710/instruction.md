When clients send a `Range` header on non-`GET` requests (notably `PATCH` and `DELETE`), PostgREST currently tries to interpret the range as if it were pagination/limiting for a read request. This causes incorrect behavior and errors when attempting limited updates/deletes, especially when the request does not include an `order` parameter.

Reproduction examples:

1) `PATCH` with a `Range` header and no `order`

```
PATCH /safe_update_items
Range: 0-0
Content-Type: application/json

{"name":"New name"}
```

This should behave like a normal update request (subject to pg-safeupdate rules), and the `Range` header should not be used to apply a limit/offset to the mutation.

Actual behavior: the request fails due to range/limit handling being applied to a mutation request, producing a server-side error. In some cases it triggers an error about requiring `order`, and in others it can reach the database and fail with:

```
"message": "syntax error at or near \"RETURNING\""
```

2) `DELETE` with a `Range` header and no `order`

```
DELETE /safe_delete_items
Range: 0-0
```

Expected behavior: the `Range` header must be ignored for `DELETE`. The delete should proceed normally (again subject to pg-safeupdate rules). It must not attempt to apply a range-based limit to the delete.

What needs to be implemented:

- Update request parsing/handling so that the `Range` header is only interpreted for `GET` requests. For other HTTP methods (`PATCH`, `POST`, `PUT`, `DELETE`), `Range` must be ignored and must not influence limit/offset, ordering requirements, or SQL generation.
- Ensure that mutation responses and headers remain correct when a `Range` header is present but ignored (e.g., `Content-Range` behavior for deletes/updates should follow the usual mutation semantics, not GET range semantics).
- The fix must cover both cases where `Range` previously caused an early validation error (e.g., requiring `order`) and cases where it previously produced invalid SQL that fails near `RETURNING`.

After the change, `PATCH`/`DELETE` requests that include `Range` should behave the same as if the header were absent, except for any unrelated, expected validation such as pg-safeupdate’s “UPDATE requires a WHERE clause” / “DELETE requires a WHERE clause” when no filter condition is present.