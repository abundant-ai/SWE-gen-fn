Requests that include a media type parameter in the `Content-Type` header (e.g. `application/json; charset=utf-8`) are incorrectly rejected with a 406-style error message:

`Content-Type not acceptable: application/json; charset=utf-8`

This is a regression introduced after v12.2.8 (it reproduces on v12.2.10), where the same requests previously succeeded.

Reproduction example:

- Send a request that includes a body (e.g. POST/PATCH/PUT) with header:
  `Content-Type: application/json; charset=utf-8`
- The server responds with an error indicating the content type is not acceptable.
- If the same request is sent with `Content-Type: application/json` (no charset parameter), it succeeds.

Expected behavior:

- `Content-Type` header parsing/validation must treat `charset=utf-8` (and similar parameters) as parameters of the media type, not as part of the media type token.
- Requests with `Content-Type: application/json; charset=utf-8` should be accepted wherever `application/json` is accepted.
- This should apply generally to media types with parameters, not only JSON.

Additionally, custom media type behavior must remain correct:

- When a response uses a media type like `text/xml`, returning `Content-Type: text/xml; charset=utf-8` is valid and should not cause content negotiation or media type matching to fail.

Fix the regression in the code that parses and compares media types so that matching/validation is performed on the base type/subtype (with parameters handled appropriately) and does not erroneously reject valid `Content-Type` values that include `charset=utf-8`.