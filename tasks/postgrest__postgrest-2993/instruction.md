PostgREST’s handling of JSON media types is inconsistent and overly duplicated across modules, which can lead to subtle mismatches in response headers—especially for error responses and RPC responses that must advertise JSON.

The codebase currently repeats the literal media type value for JSON (e.g., "application/json") in multiple places, and different components may construct or compare the JSON content type slightly differently (for example, with/without charset parameters, or by using different constructors/representations). This duplication makes it easy for one location to drift from another and can cause responses to miss the expected JSON Content-Type header or to return a Content-Type value that fails equality checks.

Refactor the JSON media type usage so that JSON is defined/represented in exactly one canonical way and reused everywhere a JSON response is produced, including error responses. Ensure that when PostgREST returns JSON payloads (including RPC responses and error responses), the Content-Type header matches the canonical JSON media type consistently.

In particular, when making an HTTP request that returns JSON (e.g., a HEAD request to an RPC endpoint that returns JSON), the response must include a JSON Content-Type header. The server should also continue to produce correct pagination/count behavior (e.g., status codes like 200 vs 206 and Content-Range headers) without any changes caused by the refactor.

Expected behavior:
- All JSON responses consistently include the same Content-Type value representing JSON.
- Error responses that return JSON also use the exact same canonical JSON media type value.
- Requests such as HEAD on JSON-producing endpoints still return the expected status code and include the JSON Content-Type header.

Actual behavior to fix:
- JSON Content-Type construction is duplicated, and at least one code path can produce a different representation or omit the expected JSON Content-Type header due to inconsistent reuse of the JSON media type value.