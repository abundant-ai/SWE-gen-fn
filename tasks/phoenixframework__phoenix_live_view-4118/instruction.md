Phoenix LiveView currently supports an opt-out mechanism for sending special “_unused” form fields, but the opt-out HTML attribute name `phx-no-usage-tracking` is confusing and misleading because it sounds like telemetry/analytics collection. The attribute should be renamed to `phx-no-unused-field` to clearly communicate that it only controls the inclusion of `_unused` form fields.

When a developer adds `phx-no-unused-field` to a form or relevant form element, LiveView should behave as if “skip unused field” is enabled: it must not send the `_unused` form field payload as part of the client-to-server form event payload.

At the same time, existing applications may already be using `phx-no-usage-tracking`. This rename must not break existing behavior unexpectedly. The system should either (a) continue to honor `phx-no-usage-tracking` as a backwards-compatible alias, or (b) provide a clear, deterministic behavior and error/warning strategy if the old attribute is used. In particular, the new name must be recognized end-to-end (rendering, DOM patching, event payload generation) so that submitting or changing a form with `phx-no-unused-field` reliably omits `_unused` fields.

Expected behavior examples:

- If a form is rendered with `phx-no-unused-field`, then triggering the form’s `phx-change` or `phx-submit` events should not include any `_unused` metadata/fields in the parameters delivered to the LiveView/LiveComponent event handler.
- If a form does not include `phx-no-unused-field` (default behavior), then unused inputs may be tracked and `_unused` fields may be included as designed.

Make sure the rename is applied consistently across client and server surfaces so there is no mismatch where the server emits one attribute name but the client only checks another, or vice versa.