PostgREST supports stripping null-valued properties from JSON responses when clients request it via the `nulls=stripped` media type parameter. Clients can request this for array and singular responses using vendor media types like:

- `Accept: application/vnd.pgrst.array+json;nulls=stripped`
- `Accept: application/vnd.pgrst.object+json;nulls=stripped`

However, PostgREST currently rejects some valid Accept values for the array vendor media type, specifically when the `+json` suffix is omitted. For example, sending:

`Accept: application/vnd.pgrst.array;nulls=stripped`

should be treated as a valid media type request (equivalent to the `application/vnd.pgrst.array+json;nulls=stripped` form for JSON responses), but it is not accepted as valid today.

This breaks clients that legitimately send `application/vnd.pgrst.array` (without `+json`) while relying on `nulls=stripped` to remove null-valued keys from JSON objects.

The fix should ensure that PostgREST accepts `application/vnd.pgrst.array` as a valid Accept media type for array JSON responses, including parameters such as `nulls=stripped`, and that it correctly applies null stripping when requested.

Expected behavior:
- A `GET` returning an array of JSON objects with some null fields should omit keys whose values are `null` when `Accept` includes `nulls=stripped`, even if the Accept is `application/vnd.pgrst.array;nulls=stripped` (no `+json`).
- `POST`, `PATCH`, etc. responses that return representations as arrays should also omit null-valued keys under the same Accept.
- The response should include a Content-Type consistent with the negotiated vendor media type for array responses and preserve the `nulls=stripped` parameter.

Actual behavior:
- Requests using `Accept: application/vnd.pgrst.array;nulls=stripped` are not accepted/negotiated correctly (treated as invalid or not matched), so null stripping does not occur and/or content negotiation fails.

Example of expected null stripping behavior:
If a row would normally be represented as:

```json
[{"id":7,"name":"John","referee":null,"auditor":null,"manager_id":6}]
```

then with `Accept: application/vnd.pgrst.array;nulls=stripped`, it should be returned as:

```json
[{"id":7,"name":"John","manager_id":6}]
```

Similarly, for updates where returned rows include null-valued columns, those keys should be absent when `nulls=stripped` is requested.