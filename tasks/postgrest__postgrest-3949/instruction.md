Ordering embedded resources is broken for mutation requests (at least PATCH), causing embedded arrays to come back in an unspecified/incorrect order even when an embedded order is requested.

Reproduction example:

- Send a PATCH request that updates a row and asks for an embedded relationship, while also specifying an order on the embedded resource via the query parameter.

For example:

PATCH /web_content?id=eq.0&select=id,name,web_content(name)&web_content.order=name.asc
Prefer: return=representation
Body: {"name": "tardis-patched"}

Expected behavior:
- The response should be a representation of the patched row (because Prefer: return=representation is set).
- The embedded `web_content` array in the response must be ordered by `name` ascending, e.g.:

[
  {
    "id": 0,
    "name": "tardis-patched",
    "web_content": [
      {"name": "bar"},
      {"name": "fezz"},
      {"name": "foo"}
    ]
  }
]

Actual behavior:
- The embedded `web_content` array is not sorted according to `web_content.order=name.asc` (it may be returned in a different order, typically insertion/plan-dependent order).

This is a regression that started after v9 (reported to have begun in v10-era changes).

The fix should ensure that embedded ordering works consistently for mutation requests that return representations (PATCH, and potentially other mutation methods that can return rows like POST/UPSERT/DELETE) whenever an embedded resource is selected and an `*.order=` parameter is provided for that embedded relationship.