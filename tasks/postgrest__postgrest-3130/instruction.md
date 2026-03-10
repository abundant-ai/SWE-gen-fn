PostgREST incorrectly rejects some custom media types when the handler is implemented via an aggregate that is not in the currently selected schema. This is a regression introduced in PostgREST 12.0.1: requests that worked in 12.0.0 now fail with HTTP 415 and error code PGRST107.

Reproduction using the media type handler example setup:
1) Define a custom domain type named exactly like the desired media type, e.g. "application/vnd.twkb" as bytea.
2) Create an aggregate (e.g. twkb_agg(lines)) whose state type (stype) is that domain, and whose transition function returns the same domain.
3) Configure PostgREST to expose one schema (e.g. db-schemas="public") and query a table that should be returned using that media type.
4) Send:

GET /lines
Accept: application/vnd.twkb

Expected behavior: PostgREST should negotiate the response media type successfully and return 200 with Content-Type: application/vnd.twkb, producing the binary payload from the handler.

Actual behavior (12.0.1): PostgREST responds with 415 Unsupported Media Type and the JSON error:

{
  "code": "PGRST107",
  "details": null,
  "hint": null,
  "message": "None of these media types are available: application/vnd.twkb"
}

This failure also shows up in multi-schema configurations: when multiple schemas are exposed and the client selects a schema via the profile header (e.g. Accept-Profile), aggregate-based media type handlers should be discoverable and work consistently regardless of which exposed schema is currently selected, as long as the relevant types/aggregates exist in an exposed schema.

Fix PostgREST so that media type handler discovery/validation properly accounts for aggregates across all configured schemas (and respects the selected profile where applicable), rather than incorrectly concluding that no handler exists for a valid Accept media type.