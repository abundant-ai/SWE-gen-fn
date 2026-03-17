Some write requests are returning an incorrect response for “no content” outcomes, particularly around PUT (and other write methods) where the server responds with an empty body but still includes a Content-Type header. This causes clients to treat the response as having a representation when it should not, and it breaks expectations that 204 responses must not include Content-Type.

When performing write operations that result in no response body (commonly status 204 No Content), the response must have an empty body and must not include a Content-Type header. This should hold consistently across DELETE, PATCH, and PUT, and also for other write endpoints when the server chooses an empty response.

Reproduction examples:

1) Deleting rows with a committed transaction:
- Request: DELETE on a table endpoint with header Prefer: tx=commit
- Expected: HTTP 204 with an empty body and no Content-Type header.
- Actual: HTTP 204 with Content-Type present.

2) Updating rows with PUT where the operation returns no representation:
- Request: PUT /items?id=eq.1 with a JSON body and no Prefer: return=representation
- Expected: HTTP 204 with an empty body, no Content-Type header, and any custom headers set by pre-request logic must still be included.
- Actual: HTTP 204 but Content-Type is present (and/or custom headers behavior is inconsistent).

3) Creating/updating with POST/PUT in cases where an empty body is returned:
- If the response body is empty, the server must not emit Content-Type even if the request body is JSON.

Additionally, custom response headers injected via pre-request logic (for example, returning an X-Custom-Header, adjusting Cache-Control, or overriding Content-Type for HEAD/GET responses) must continue to work, but they must not force a Content-Type to appear on 204/empty-body responses. In other words:
- For HEAD/GET responses with a real media type, Content-Type should be present (and overridable).
- For 204 No Content (and any response with an intentionally empty body), Content-Type must be absent, regardless of request content type or default behavior.

Fix the response construction so that:
- 204 responses never include Content-Type.
- Empty-body write responses behave consistently for PUT/POST/PATCH/DELETE.
- Pre-request header injection continues to apply, but does not cause Content-Type to be added when the response is “no content.”