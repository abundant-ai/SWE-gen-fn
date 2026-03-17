PostgREST returns inconsistent HTTP responses for PostgreSQL functions declared as `RETURNS void`, depending on the function language. For example, calling an RPC function that returns `void` may respond `200 OK` with a JSON body of either `""` (empty string) or `null`. This is inconsistent and does not reflect that the procedure returns no content.

When invoking an RPC endpoint backed by a `RETURNS void` function (e.g. `GET /rpc/x` or `POST /rpc/x`), PostgREST should instead respond with `204 No Content` and no response body. The response must not include a `Content-Type` header when the body is empty.

This “no content means no content-type” rule should be applied consistently to any `204 No Content` response produced by PostgREST, including non-RPC write operations (e.g. `PUT`) that return `204`. Currently, some `204` responses are emitted with an empty body but still include a `Content-Type: application/json` header; this should be corrected so that `Content-Type` is absent when the response body is empty.

Reproduction example (database side):

```sql
CREATE FUNCTION x() RETURNS VOID AS $$ BEGIN
END $$ LANGUAGE plpgsql;

CREATE FUNCTION z() RETURNS VOID AS $$ $$ LANGUAGE sql;
```

Current behavior:
- `GET /rpc/x` returns `200 OK` with body `""`.
- `GET /rpc/z` returns `200 OK` with body `null`.

Expected behavior:
- Both `GET /rpc/x` and `GET /rpc/z` return `204 No Content`.
- The response body is completely empty.
- The `Content-Type` header is not present when the body is empty.

The change should make `RETURNS void` RPC behavior consistent across function languages and ensure `204` responses do not send a `Content-Type` header when there is no response body.