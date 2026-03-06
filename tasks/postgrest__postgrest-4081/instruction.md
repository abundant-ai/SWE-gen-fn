When PostgREST receives a request with a JWT whose `role` claim names a database role that does not exist (or is not valid on the server), it currently responds with HTTP 400. This is inconsistent with other JWT-related failures (e.g., invalid signature, expired token, invalid claims), which respond with HTTP 401.

Reproduce by starting PostgREST with JWT enabled and making a request to any protected endpoint using an `Authorization: Bearer <token>` header where the token is otherwise well-formed/validly signed but contains a `role` claim such as `{"role": "this_role_does_not_exist"}`. The server currently returns a 400 response.

Expected behavior: JWT authentication failures should be classified consistently as authentication errors. If the JWT is validly formatted/signed but the `role` claim refers to an invalid/nonexistent role, PostgREST should return HTTP 401 (not 400), in the same way as other JWT errors.

Actual behavior: The server returns HTTP 400 for the invalid/nonexistent role case.

Fix the JWT error-to-HTTP-status mapping so that the invalid-role JWT scenario results in a 401 response. The response should be treated as an authentication failure (not a generic client input/JSON error), and it should behave consistently with the other JWT error cases handled by PostgREST.