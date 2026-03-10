PostgREST currently accepts any unrecognized `Prefer` tokens and silently ignores them. For example, sending `Prefer: anything` on a normal GET request still returns `200 OK` and the request succeeds. This makes it hard for clients to detect whether a deployed PostgREST instance supports the `Prefer` values they are sending.

Add support for the RFC 7240 preference `handling=strict` / `handling=lenient` in the `Prefer` request header.

When a request includes `Prefer: handling=strict`, PostgREST must validate all provided `Prefer` preferences and reject any unrecognized/unsupported preference values. In this case the response must be a `400 Bad Request` with a JSON error object with:

- `code`: `PGRST122`
- `message`: `Invalid preferences given with handling=strict`
- `details`: a string listing the invalid preferences in the order they were provided, formatted like `Invalid preferences: <pref1>, <pref2>`
- `hint`: `null`

Examples that must fail with the above error shape:

- `GET /items` with header `Prefer: handling=strict, anything` must return 400 and `details` must be `Invalid preferences: anything`.
- If multiple `Prefer` headers are sent, they must be combined for validation. For example `GET /items` with headers `Prefer: handling=strict` and `Prefer: something, else` must return 400 with `details` equal to `Invalid preferences: something, else`.
- The same strict behavior must apply consistently across request types, including writes and RPC:
  - `POST /organizations?select=*` with `Prefer: return=representation, handling=strict, anything` must return 400 with the same `PGRST122` error.
  - `POST /rpc/overloaded_unnamed_param` with JSON body `{}` and `Prefer: handling=strict, anything` must return 400 with the same `PGRST122` error.

When a request includes `Prefer: handling=lenient`, PostgREST must keep the current behavior: accept the request and ignore unrecognized preferences (no error). This lenient behavior must also work when `Prefer` values are split across multiple `Prefer` headers.

Examples that must succeed:

- `GET /items` with `Prefer: handling=lenient, anything` must succeed (200).
- `GET /items` with `Prefer: handling=lenient` and a second header `Prefer: anything` must succeed (200).
- `POST /organizations?select=*` with `Prefer: return=representation, handling=lenient, anything` must succeed and return the normal successful insert response (201 with representation body when `return=representation` is present).

If neither `handling=strict` nor `handling=lenient` is provided, the default must remain lenient (i.e., unknown preferences are ignored, as today).