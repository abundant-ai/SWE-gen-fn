RPC endpoints should be able to return PostgreSQL values of type `xml` as an actual XML HTTP response when the client requests it, but current behavior does not reliably support this.

When calling an RPC function that returns `xml`, PostgREST should honor content negotiation such that a request with header `Accept: text/xml` returns a response body containing the raw XML (not JSON-encoded/quoted) and sets the response `Content-Type` appropriately (e.g. `text/xml; charset=utf-8`). This must work for:

1) Scalar RPC return type `xml`: the response body should be the XML value directly.

2) Set-returning/table RPC results involving XML values: the response should be a concatenation of the returned XML fragments (e.g. a result set of XML values becomes a single XML payload by concatenating each row’s XML output in order).

Currently, XML RPC behavior is either unsupported or inconsistent: users are forced to return `text` and manually set `response.headers` to `content-type: text/xml`, and attempts to return `xml` can fail during aggregation with database errors like:

`Function string_agg(xml, unknown) does not exist`

Additionally, if `Accept: text/xml` is not provided, XML-returning scalar RPCs should not produce an invalid response or crash; the server should respond deterministically (either by choosing a supported default representation or by returning a clear error indicating the requested/selected media type is incompatible).

Example scenario that should work:

- A function `soap_endpoint(xml) RETURNS xml` should be callable via `/rpc/soap_endpoint` and, when requested with `Accept: text/xml`, should return the XML response body as-is with an XML content type.

The implementation should ensure that XML output is handled without JSON string escaping/double-quoting, and that XML aggregation uses semantics compatible with PostgreSQL’s `xml` type (so set-returning/table RPCs can be rendered without relying on `string_agg(xml, ...)`).