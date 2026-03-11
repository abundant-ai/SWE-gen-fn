When debug annotations are enabled globally (via application config), HEEx templates rendered through Phoenix LiveView add debugging markup (HEEx debug annotations) and may also include debug-related attributes. This is useful for development, but currently there is no reliable way to opt out for a specific component/module when the global setting is on.

Add support for opting out of debug HEEx annotations and debug attributes on a per-module basis.

Specifically, a component module that uses `Phoenix.Component` should be able to set module attributes like `@debug_heex_annotations false` and `@debug_attributes false` to disable those behaviors for templates compiled in that module, even if the application environment has `:phoenix_live_view, :debug_heex_annotations` and/or `:phoenix_live_view, :debug_attributes` set to `true`.

Expected behavior:
- If the global config enables debug annotations, templates compiled in most modules should still include the debug annotations as they do today.
- If a module defines `@debug_heex_annotations false`, then HEEx rendered from that module must not include HEEx debug annotations.
- If a module defines `@debug_attributes false`, then HEEx rendered from that module must not include the debug-related attributes.
- The opt-out should apply to templates compiled within that module, including templates inside function components and content rendered through slots (e.g., content produced by `render_slot/1` and `render_slot/2`).

Actual behavior to fix:
- With debug annotations enabled globally, modules cannot currently disable debug annotations/attributes locally, so debug markup/attributes still appear even when the module sets `@debug_heex_annotations false` and `@debug_attributes false`.

Implement the per-module override so that the compiler/engine respects these module attributes during HEEx compilation/rendering in Phoenix LiveView.