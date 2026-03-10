PostgREST still accepts the HTTP preference `Prefer: params=single-object` on RPC calls, but support for this behavior has been deprecated and is planned to be removed in the next major version. The server should no longer recognize or act on `Prefer: params=single-object` for `/rpc/*` requests.

Currently, clients can call a PostgreSQL function that takes a single JSON/JSONB parameter by sending a JSON object body along with `Prefer: params=single-object`, which makes PostgREST treat that JSON object as the single function argument. This legacy mode must be removed.

When an RPC request includes `Prefer: params=single-object`, PostgREST should reject the request rather than attempting to interpret parameters using that preference. The response must be an error (4xx) that clearly indicates the preference is no longer supported/deprecated/invalid. The preference should not silently change behavior, and it should not be accepted as a valid `Prefer` token.

RPC calls must continue to work without this preference:
- RPC with query string parameters (e.g. `/rpc/myfunc?min=2&max=4`) should behave as before.
- RPC with a JSON body that matches the function’s named parameters (e.g. `{ "min": 2, "max": 4 }`) should behave as before.
- Other `Prefer` directives (for example `Prefer: count=exact`) must remain supported and continue to affect responses as they currently do.

In short: remove support for the `params=single-object` preference entirely, ensure it is treated as invalid on incoming requests, and ensure normal RPC parameter passing mechanisms and other preferences remain unaffected.