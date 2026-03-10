When a client requests the singular object media type via the Accept header (e.g., `Accept: application/vnd.pgrst.object+json`) but the request cannot be satisfied (such as when the query returns multiple rows or zero rows), PostgREST correctly returns `406 Not Acceptable` with error code `PGRST116`, but the response headers are wrong.

Currently, the error response may include the rejected vendor media type in the `Content-Type` header, and can even include multiple `Content-Type` headers. For example, a request like:

```bash
curl -i 'http://localhost:3000/projects' -H 'Accept: application/vnd.pgrst.object+json'
```

can return `406 Not Acceptable` with two `Content-Type` headers, including:

- `Content-Type: application/json; charset=utf-8`
- `Content-Type: application/vnd.pgrst.object+json; charset=utf-8`

This is incorrect because the server rejected that vendor media type; error responses should be emitted as regular JSON.

Fix the response generation so that when `application/vnd.pgrst.object+json` (including parameterized variants like `application/vnd.pgrst.object+json;nulls=stripped`) is rejected and a `406 Not Acceptable` error is returned, the response contains exactly one `Content-Type` header and it must be:

```
application/json; charset=utf-8
```

The body should remain a JSON error object (e.g., for `PGRST116`: `{"code":"PGRST116","message":"JSON object requested, multiple (or no) rows returned","details":"The result contains N rows","hint":null}`), but the `Content-Type` must not reflect the rejected vendor media type, and duplicate/multiple `Content-Type` headers must not be produced.