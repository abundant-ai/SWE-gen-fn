LiveView’s usage tracking for `phx-*` bindings is incorrectly treating bindings that start with the prefix `_unused_` as “used”. This is a problem because upstream integrations may intentionally emit placeholder bindings like `phx-change="_unused_validate"` (or similar `_unused_*` names) to suppress warnings/usage tracking, and LiveView should not count these as real usage.

When a form or element includes `phx-*` attributes whose event name begins with `_unused_` (for example, `phx-change="_unused_validate"`, `phx-submit="_unused_save"`, or other `phx-` bindings pointing at `_unused_*`), LiveView should behave as if that binding is not present for purposes of usage tracking. In other words:

- LiveView should not mark those bindings as used, and should not emit usage-tracking metadata for them.
- Any logic that depends on “was this binding used?” should ignore `_unused_*` bindings.

At the same time, normal, non-`_unused_*` bindings must continue to work and be tracked as before. Form behavior around submit/disable/readonly restoration must remain correct: submitting forms should still temporarily set disabled/readonly states during submission and then restore them afterward, for both top-level LiveViews and nested scenarios, and for both form submit buttons and non-form buttons using `phx-disable-with`.

Reproduction example:

```elixir
~H"""
<form phx-change="_unused_validate" phx-submit="save">
  <input name="a" readonly />
  <button id="submit" phx-disable-with="Saving...">Save</button>
</form>
"""

# Expected: `_unused_validate` is ignored by usage tracking.
# Actual: LiveView counts `_unused_validate` as usage, causing incorrect tracking/warnings.
```

Fix the usage-tracking logic so that any `phx-*` event name starting with `_unused_` is excluded from tracking, without breaking form submission state restoration behavior.