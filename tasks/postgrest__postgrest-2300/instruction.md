Calling an RPC endpoint with a PostgreSQL function that has a single unnamed parameter of type xml should accept raw XML request bodies and return XML responses cleanly, but currently PostgREST does not properly support this flow.

When a function is defined like:

```sql
create function soap_endpoint(xml) returns xml as $$ ... $$ language sql;
```

and the client sends a POST request to `/rpc/soap_endpoint` with an XML payload (for example `<Envelope>...</Envelope>`), PostgREST should accept the request when the `Content-Type` is one of:

- `text/xml`
- `application/xml`
- `application/soap+xml`

For these content types, the raw request body must be passed as the single unnamed xml argument to the function (analogous to how raw `text/plain` works for a single unnamed `text` parameter).

Currently, XML RPC POST either isn’t accepted as a raw body for an unnamed xml parameter, or requires awkward header workarounds (e.g., sending `Content-Type: text/plain` and forcing `Accept: text/plain` to avoid the body being treated/encoded as JSON text). This prevents writing SOAP-like endpoints naturally.

Additionally, when the RPC function returns the PostgreSQL `xml` type, PostgREST should respond with an XML content type automatically (at minimum `text/xml; charset=utf-8` or an equivalent XML media type) rather than defaulting to JSON rendering or requiring the function to manually set `response.headers`.

Finally, returning `xml` must not fail during response aggregation/formatting. Today, returning `xml` can trigger a PostgreSQL error like:

```
Function string_agg(xml, unknown) does not exist
```

PostgREST must be able to render responses for functions returning xml without hitting this error (including cases where the function returns a set of rows/values), producing a valid XML response body.

Example expected behavior:
- POST `/rpc/soap_endpoint` with header `Content-Type: text/xml` and a raw XML body should call the function with that XML as its only argument.
- If the function returns xml, the HTTP response should have an XML `Content-Type` and the body should be the XML content (not JSON-quoted, not wrapped as a JSON string).
- The request should not require `Accept: text/plain` to avoid quoting/encoding artifacts; XML responses should be served as XML when the return type is xml.