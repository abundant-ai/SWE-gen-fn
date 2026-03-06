When `jwt-aud` is configured, PostgREST should validate the JWT `aud` (audience) claim correctly for both of the standard JWT representations: a single string and an array of strings. A regression causes tokens that use an array audience (e.g. `"aud": ["youraudience"]`) to be rejected even when one of the array elements matches the configured `jwt-aud`.

Reproduction: configure PostgREST with `jwt-aud = "youraudience"`, then send a request with an `Authorization: Bearer <jwt>` header where the JWT payload includes a valid `exp`, a valid `role`, and an audience claim expressed as an array, for example:

```json
{
  "exp": 9999999999,
  "role": "postgrest_test_author",
  "id": "jdoe",
  "aud": ["notyouraudience", "youraudience", "anotheraudience"]
}
```

Expected behavior: the request is authorized (e.g. succeeds with HTTP 200) as long as at least one element of the `aud` array equals the configured `jwt-aud` value.

Actual behavior: the request is rejected with HTTP 401 and the error payload:

```json
{"code":"PGRST303","details":null,"hint":null,"message":"JWT not in audience"}
```

The audience validation must behave as follows when `jwt-aud` is set:

- If `aud` is a string, accept the token only when it exactly matches `jwt-aud`; otherwise reject with the 401 `PGRST303` response above.
- If `aud` is an array of strings, accept the token when any element exactly matches `jwt-aud`; otherwise reject with the same 401 `PGRST303` response.
- If `aud` is an empty string or an empty array, treat it as not matching and reject with the same 401 `PGRST303` response.

Implement/fix the JWT claim parsing/validation so that array-valued `aud` claims are handled correctly without breaking the existing string-audience behavior.