PostgREST should support an optional way for clients to omit object properties whose values are JSON null in the response payload.

Currently, when querying resources that include nullable columns (for example, a polymorphic view that left-joins multiple tables), PostgREST returns JSON objects containing keys with null values, e.g.

```json
{
  "contact_id": "...",
  "contact_type": "company",
  "company_name": "Nerfpops Incorporated",
  "preferred_name": null,
  "email": null
}
```

Add support for a `nulls=stripped` parameter on the vendor JSON media types so that clients can request null-valued properties be removed from the JSON objects in the response.

When the client sends an `Accept` header of:

- `application/vnd.pgrst.array+json;nulls=stripped`

then any JSON array response of objects must omit keys whose values are `null` from each object in the array. This must apply to normal reads and also to write requests that return representations (e.g. when inserting/updating with `Prefer: return=representation`). For example, if an insert returns a representation like:

```json
[{"id":7,"name":"John","referee":null,"auditor":null,"manager_id":6}]
```

it must instead return:

```json
[{"id":7,"name":"John","manager_id":6}]
```

Similarly, if an update returns a representation containing a null field, that field must be omitted from the returned object(s).

- `application/vnd.pgrst.object+json;nulls=stripped`

then any singular-object JSON response must omit keys whose values are `null`.

This behavior must occur even when the client explicitly selects the nullable columns via `select=...`; i.e., explicit selection does not override stripping—if the value is `null`, the property should not appear in the JSON.

Content negotiation must preserve the vendor media type in the response `Content-Type` header, including the `nulls=stripped` parameter, e.g. `application/vnd.pgrst.array+json;nulls=stripped; charset=utf-8` and `application/vnd.pgrst.object+json;nulls=stripped; charset=utf-8`.

The existing semantics for the singular object media type must remain: if a client requests `application/vnd.pgrst.object+json;nulls=stripped` but the result is not singular (multiple rows or zero rows), the request must fail with HTTP 406 and the same error payload shape/message as the non-stripped singular-object behavior (e.g. message indicating a JSON object was requested but multiple (or no) rows were returned, with an error code like `PGRST116`). In this error response, do not strip `null` fields from the error object; for example, an error response may still include `"hint": null`.

When `nulls=stripped` is not present, responses must remain unchanged and continue to include explicit `null` values as they do today.