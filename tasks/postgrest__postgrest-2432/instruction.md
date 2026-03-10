When requesting an execution plan from the API, the default output format should be plain text, but it currently defaults to JSON unless the client explicitly asks for JSON.

Reproduction:
- Make a GET request to any resource with plan enabled (e.g. a filtered table/view request) and request the plan media type without specifying a format suffix such as +json.

Expected behavior:
- If the client sends an Accept header for the plan media type without an explicit format suffix (e.g. `Accept: application/vnd.pgrst.plan`), the response should default to the text plan format.
- The response `Content-Type` should indicate the plan media type using the default text representation (i.e., not `...plan+json`).
- If the client explicitly requests JSON (e.g. `Accept: application/vnd.pgrst.plan+json`), the response must remain JSON and preserve existing JSON structure/fields (for example, plan fields like `Plan` and `Total Cost` must still be present and parseable).
- Any plan-related parameters in the media type (for example `options=buffers`) must continue to work and be reflected in `Content-Type` appropriately, independent of whether the output is text or JSON.

Actual behavior:
- Requests that ask for the plan media type without a `+json`/format suffix are treated as JSON by default, resulting in a JSON plan response and a `Content-Type` like `application/vnd.pgrst.plan+json; charset=utf-8`, contrary to the intended default.

Fix the content negotiation/plan formatting selection so that the plan endpoint defaults to text output unless the client explicitly requests JSON. Ensure existing behavior for explicit `application/vnd.pgrst.plan+json` remains unchanged, including status code 200 responses and correct `Content-Type` headers with any provided plan options.