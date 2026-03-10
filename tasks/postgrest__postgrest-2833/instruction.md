When clients request an execution plan using the vendor media type `application/vnd.pgrst.plan+json`, PostgREST currently handles the media type parameters too loosely/inconsistently. This leads to incorrect or non-canonical `Content-Type` responses and unreliable propagation of plan-related parameters.

The plan output endpoint must treat `application/vnd.pgrst.plan+json` as a strict media type with explicit parameter semantics:

- For a request with `Accept: application/vnd.pgrst.plan+json`, the response must include a `Content-Type` header exactly of the form:
  `application/vnd.pgrst.plan+json; for="application/json"; charset=utf-8`
  (i.e., it must include the `for="application/json"` parameter and `charset=utf-8`).

- If the request includes an `options` parameter on the plan media type (e.g. `Accept: application/vnd.pgrst.plan+json; options=buffers`), the response `Content-Type` must preserve it and return:
  `application/vnd.pgrst.plan+json; for="application/json"; options=buffers; charset=utf-8`

- If multiple options are provided (e.g. `options=analyze|buffers`), the server must accept them as part of the plan media type request, forward them to the underlying `EXPLAIN` configuration, and keep the `options` parameter in the response `Content-Type`.

- The plan response body must reflect requested plan options. For example, when `options=buffers` is requested (or `analyze|buffers` where required), the returned plan JSON must include buffer/block information such as `"Shared Hit Blocks"` in the appropriate place in the plan output.

Currently, requests that should produce the above canonical `Content-Type` (and option-dependent plan content) may instead omit the `for` parameter, drop or reorder parameters inconsistently, or fail to apply `options` strictly as plan parameters. Fix the plan media type parsing/normalization so that `Accept` negotiation for `application/vnd.pgrst.plan+json` is strict and deterministic, and ensure the response headers and plan body consistently reflect the requested plan options.