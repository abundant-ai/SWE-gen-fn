Requests that include the query parameter `limit=0` currently behave incorrectly.

When a client performs a request like:

```bash
curl -X GET "http://localhost:3000/projects?limit=0"
```

PostgREST can crash with a fatal error:

```
FatalError {fatalErrorMessage = "range without lower bound"}
```

Instead of returning a normal HTTP response.

This failure is especially severe when a database pool is configured, because each fatal error permanently consumes a pool connection. With `PGRST_DB_POOL=1`, repeating the request can make PostgREST become unresponsive.

The server should accept `limit=0` as a valid request meaning “return zero rows”, and it should respond successfully with an empty JSON array (`[]`) rather than crashing.

In addition, the HTTP range metadata for empty results must be correct. When the response body is empty due to a zero-length selection (e.g. `limit=0` or an empty computed range from an RPC), the `Content-Range` header must be:

```
Content-Range: */*
```

(when the total count is not requested/unknown), and the request should return a successful status code (200).

The behavior must work consistently for both normal table reads and RPC endpoints that return ranged/collection results, including when a `Range` header is present. Open-ended ranges must continue to be accepted, and when the computed result set is empty the body must be `[]` with `Content-Range: */*` rather than raising an error or returning an invalid range.