When generating a new Phoenix application with Gettext enabled, not all user-facing strings included in the generated code are marked for translation. As a result, running `mix gettext.extract` on a freshly generated project misses many built-in UI strings, and the app ships with several English-only messages by default.

Reproduction:
1) Generate a new app: `mix phx.new hello` (with default options that include Gettext).
2) Run `mix gettext.extract`.

Actual behavior:
Many strings that appear in the generated UI are not wrapped in Gettext calls, so they do not appear in the extracted `.pot` files. Examples include default flash/error messages and other component text that can appear at runtime (e.g., messages like "We can't find the internet" and "Something went wrong!").

Expected behavior:
All user-facing strings that ship in the generated app’s reusable components should be consistently wrapped for translation so they are picked up by `mix gettext.extract`. The generated components module should not leave behind unmarked, runtime-visible text; instead, such strings should be emitted using the appropriate Gettext call for their context.

Additional requirement:
Phoenix has two sources that must produce the same generated `core_components` content (the installer template and the LiveView generator’s template). After the change, these two templates must remain byte-for-byte identical so that apps generated via different entry points include the same Gettext-wrapped strings and behavior.