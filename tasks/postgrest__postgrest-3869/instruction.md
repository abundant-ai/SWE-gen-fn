When a client sends a request targeting a table (endpoint) that does not exist, PostgREST should return a proper JSON error response with a non-empty message and the correct HTTP status. Currently, some code paths produce an empty error JSON (raising an effectively “empty error” in client SDKs), and other paths can return a misleading 400 error when resource embedding is present.

Reproduction examples:

1) Non-existing table for writes (insert/upsert)
- Configure a client to use a table name that does not exist (e.g., a typo).
- Attempt an insert or upsert.
- Actual: the server response can lead clients to raise an error object with no useful fields/message (empty error).
- Expected: return a structured JSON error explaining that the relation/table does not exist.

2) Non-existing endpoint with resource embedding
- Request an endpoint that does not exist but includes embedding in the select parameter, e.g.:
  GET /none_existing_endpoint?select=title,directors(id,last_name)
- Actual: returns HTTP 400 with an error like code "PGRST200" complaining about missing relationships between the (non-existing) endpoint and embedded resources.
- Expected: return HTTP 404 indicating the endpoint/table itself does not exist (a missing relation), with a JSON error describing that the table could not be found.

Required behavior
- Introduce and use a dedicated error for missing tables/endpoints (e.g., a "TableNotFound"-style API error) so that responses are never empty in these scenarios.
- For requests to a non-existing table, respond with HTTP 404 and a JSON body containing:
  - a stable error "code" identifying missing table in the schema cache (e.g., "PGRST205")
  - "message" that clearly states the table could not be found in the schema cache and includes the qualified table name
  - "details" as null
  - "hint" populated when a close match exists (e.g., "Perhaps you meant the table 'test.factories'")

Concrete example of the expected response format for a missing table endpoint:

- Request:
  GET /fakefake
- Response:
  Status: 404
  Body:
  {"code":"PGRST205","details":null,"hint":"Perhaps you meant the table 'test.factories'","message":"Could not find the table 'test.fakefake' in the schema cache"}

This behavior should be consistent across request types (reads and writes) and should take precedence over embedding/relationship-resolution errors: if the root endpoint table does not exist, return the missing-table 404 error rather than a 400 relationship error.