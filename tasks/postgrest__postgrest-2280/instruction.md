Self-referential relationships (a table or view relating back to itself) are not handled correctly in relationship discovery and embedding, especially when the self-relationship is exposed through a view. This can lead to incorrect embedding resolution and/or missing or incorrect OpenAPI schema output for resources that have self-relationships.

When requesting the API root with `Accept: application/openapi+json`, the server should still return a valid OpenAPI document with `Content-Type: application/openapi+json; charset=utf-8`. Separately, when requesting the API root with `Accept: application/json`, the response should include entries that reflect available schema-qualified resources (including view-backed resources involved in these relationships) rather than failing or omitting expected resources.

Additionally, embedding resolution must continue to properly disambiguate relationships when multiple candidate relationships exist. For ambiguous embeds, requests must return HTTP 300 with error code `PGRST201`, and the error payload must include:

- `message`: `"Could not embed because more than one relationship was found for '<source>' and '<embed>'"`
- `hint` listing the disambiguation options using the `!` syntax (e.g. `person!message_sender_fkey` and `person_detail!message_sender_fkey`)
- `details` entries describing each candidate relationship, including `cardinality`, a human-readable `relationship` description, and `embedding`.

Concrete examples that must behave as described:

1) A request like `GET /message?select=id,body,sender(name,sent)` must return 300 Multiple Choices with `code: "PGRST201"` when both a table and a view provide competing relationships for the same embed path.

2) A request like `GET /activities?select=fst_shift(*)` must return the same 300/PGRST201 behavior for composite-key relationships when both a table and a view point to the same logical relationship.

The underlying issue to fix is that self-relationships on views are not being represented/reflected consistently in the relationship graph used for embedding and schema generation. After the change, self-relationships must be discovered and represented in a way that does not break root discovery/OpenAPI output, and does not regress relationship disambiguation behavior (including correct 300 responses and error payload structure) in the presence of table/view overlap.