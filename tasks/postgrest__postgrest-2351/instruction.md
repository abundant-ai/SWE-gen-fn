When inserting rows with PostgREST, the server currently computes and returns a `Location` header even when the client requests `Prefer: return=representation`. This is wasteful because the full representation is already returned in the response body, and the client does not need to follow the `Location` link.

Repro:

```http
POST /table_name HTTP/1.1
Prefer: return=representation
Content-Type: application/json

{ "col1": "value1", "col2": "value2" }
```

Actual behavior: the response includes a `Location` header (and the server performs extra work to compute it, including building a header value from the inserted row’s primary key columns).

Expected behavior:
- The `Location` header must be returned only when the client explicitly uses `Prefer: return=headers-only`.
- For `Prefer: return=representation`, PostgREST must not compute or emit the `Location` header.
- For requests with no `Prefer` return specified (default behavior) and for `Prefer: return=minimal`, PostgREST must not compute or emit the `Location` header.

This change must preserve existing behavior for status codes and response bodies:
- `return=representation` should continue returning `201` with a JSON body containing the inserted rows (respecting `select` when applicable).
- `return=minimal` (and the default when no return preference is specified) should continue returning `201` with an empty body and no `Content-Type` header.

The key fix is to ensure the logic that decides whether to compute the `Location` header is gated strictly on `Prefer: return=headers-only`, not on other return modes.