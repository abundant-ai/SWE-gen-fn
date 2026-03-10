CORS preflight/OPTIONS requests incorrectly reject valid `Accept` media types with `415 Unsupported Media Type`.

Reproduction:

```bash
curl -X OPTIONS "http://localhost:3000/projects" -H "Accept: text/csv" -I
# HTTP/1.1 200 OK

curl -X OPTIONS "http://localhost:3000/projects" -H "Accept: application/json" -I
# HTTP/1.1 415 Unsupported Media Type   (current behavior, wrong)
```

This happens because OPTIONS responses are treated as if they only support a specific media type (effectively hardcoded), so content negotiation/validation fails for other media types even though OPTIONS should be permissive and independent from the resource representation.

Update the request handling so that when the request method is `OPTIONS`, the server accepts all available/known media types for the `Accept` header (including custom ones like `application/geo+json`) and does not return 415 solely due to the `Accept` value.

Expected behavior:
- `OPTIONS` requests to endpoints like `/items`, `/projects`, `/shops`, etc. should return a successful response (e.g., 200 with an empty body is fine) even when `Accept` is `application/json` or other supported/custom media types.
- CORS-related headers (e.g., `Access-Control-Allow-Origin`) must still be included as appropriate.

Actual behavior:
- `OPTIONS` succeeds for some `Accept` values (e.g., `text/csv` or `*/*`) but returns `415 Unsupported Media Type` for `Accept: application/json` and potentially other non-CSV media types.