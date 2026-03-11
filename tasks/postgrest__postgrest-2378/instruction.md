PostgREST does not correctly handle the HTTP OPTIONS method for RPC endpoints and the API root path.

Currently, sending an OPTIONS request to an RPC endpoint like:

```http
OPTIONS /rpc/func_name
```

returns a failure (commonly a 405 with a body such as `{"message":"Bad Request"}`), rather than responding with a valid `Allow` header as required by RFC 7231.

The server should accept OPTIONS on `/rpc/<function>` and on `/` (the root path) and respond with a successful OPTIONS response that includes an `Allow` response header listing the methods that are permitted for that target.

For RPC endpoints, the set of allowed methods must depend on the function’s volatility:

- For STABLE/IMMUTABLE functions, `GET` and `HEAD` should be allowed in addition to `POST` (and `OPTIONS`).
- For VOLATILE functions, `GET` and `HEAD` must not be allowed; only `POST` (and `OPTIONS`) should be advertised and accepted.

In addition to returning the correct `Allow` header on OPTIONS, method enforcement must match what is advertised:

- If a function is VOLATILE and the client performs `GET /rpc/<func>?...`, the request must be rejected with HTTP 405 Method Not Allowed (rather than being processed successfully).
- If a function is not VOLATILE, `GET` and `HEAD` to `/rpc/<func>` should continue to work as they do today.

The behavior should be consistent with existing method discovery on other resources: OPTIONS should succeed for valid targets and return 404 for unknown targets. The `Allow` header should include `OPTIONS` and list methods in a consistent comma-separated format (for example: `Allow: OPTIONS,GET,HEAD,POST` for non-volatile RPC functions, and `Allow: OPTIONS,POST` for volatile ones).