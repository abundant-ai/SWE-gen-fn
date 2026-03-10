Ordering of embedded resources is broken on PATCH requests when using the dot-notation embed order parameter. For example, a PATCH request like:

PATCH /web_content?id=eq.0&select=id,name,web_content(name)&web_content.order=name.asc
Prefer: return=representation
Body: {"name": "tardis-patched"}

should return the patched row along with the embedded `web_content` array ordered by `name` ascending (e.g., `bar`, `fezz`, `foo`). Instead, the embedded ordering is ignored or not applied during PATCH (even though similar embedded ordering works for GET), causing the embedded array to come back unsorted.

This regression was introduced between v9 and v10 (notably after commit e90391b7ac). Embedded filters had similar regressions that were fixed previously, so embedded ordering on non-GET requests likely isn’t being parsed/attached to the embedded resource correctly.

Fix the request query parameter parsing so that embedded ordering parameters like `web_content.order=name.asc` are correctly recognized and applied for PATCH requests (and, by extension, should behave consistently for other non-GET methods that return representations). The behavior must work when `Prefer: return=representation` is used, and it must not break existing handling of top-level `order=` or embedded filters/select syntax.

Expected behavior: PATCH with `Prefer: return=representation` returns the updated resource with embedded resources ordered according to `<embed>.order=...`.
Actual behavior: embedded order is not honored for PATCH; the embedded array order is incorrect/unspecified.