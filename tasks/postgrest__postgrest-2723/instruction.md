PostgREST currently does not correctly implement the updated Prefer header semantics for handling missing fields/defaults during mutations. The API should support the preference token `missing=default` in the `Prefer` request header, and treat it as the way to request that omitted columns use their database defaults.

At the moment, requests that specify defaults for missing fields either require/accept an older preference token (e.g., `missing=default` is ignored or mis-parsed), or result in behavior inconsistent with other Prefer tokens like `return=representation` and `return=minimal`. This leads to incorrect insert/update behavior when a JSON payload omits columns that have defaults in the database: the server may insert `NULL`/omit the default application, or behave as if no preference was supplied.

Implement support so that when a client sends mutation requests (at minimum INSERT and PATCH/UPDATE) with:

```http
Prefer: missing=default
```

then for any column not present in the JSON body, PostgREST should generate the SQL in a way that the database default is used (rather than explicitly inserting NULL or otherwise preventing defaults).

This should work correctly in combination with other Prefer tokens in the same header, for example:

```http
Prefer: return=representation, missing=default
```

Expected behavior:
- `Prefer: missing=default` is recognized and parsed as a valid preference token.
- For INSERT and PATCH requests, missing fields in the request body should use database defaults when this preference is provided.
- The preference should not break existing behavior for empty responses (e.g., 201 with empty body should not set Content-Type; 204 responses should not set Content-Type).
- Combining `missing=default` with `return=representation` should still return the correct JSON representation and status codes for successful mutations.

Actual behavior to fix:
- `Prefer: missing=default` is not honored (or is treated as an unknown/ignored preference), so omitted fields do not get their defaults applied.
- In some cases, interactions with return preferences lead to incorrect response behavior (wrong body/headers/status) when `missing=default` is used.

Update the relevant Prefer parsing/representation so that `missing=default` is the supported token (and ensure any legacy token, if previously supported, is either mapped consistently or rejected consistently), and ensure the mutation logic applies defaults as described.