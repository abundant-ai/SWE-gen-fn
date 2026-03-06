Requests that include media type parameters in the `Content-Type` header (notably `charset=utf-8`) are incorrectly rejected with a 415-style error message. In PostgREST v12.2.10, sending `Content-Type: application/json; charset=utf-8` causes the request to fail with:

`Content-Type not acceptable: application/json; charset=utf-8`

The same request succeeds when the header is `Content-Type: application/json` (no parameters), and it also worked in v12.2.8, so this is a regression.

PostgREST should treat `application/json; charset=utf-8` as `application/json` for the purpose of matching/validating the request body media type. Media type parameters (like `charset`) must not cause a mismatch when determining whether the incoming `Content-Type` is acceptable.

Reproduction example:

- Send a request that includes a JSON body (e.g., POST/PATCH) with header `Content-Type: application/json; charset=utf-8`.
- Current behavior: request is rejected with `Content-Type not acceptable: application/json; charset=utf-8`.
- Expected behavior: request is processed the same as if `Content-Type` were `application/json` (i.e., accepted and handled normally).

Implement the fix in the code paths that parse and validate request media types so that media type comparison/matching ignores parameters. Ensure that the original `Content-Type` may still be preserved where appropriate for response headers or logging, but acceptance checks must not fail solely due to the presence of `; charset=utf-8` (or similar parameters).