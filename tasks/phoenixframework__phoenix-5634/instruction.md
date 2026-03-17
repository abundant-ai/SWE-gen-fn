Generating a new Phoenix 1.7 project currently vendors the full Heroicons SVG set into the generated app (for example under the app’s assets vendor directory). This adds several megabytes to the freshly generated repository and to container/release builds even when the application only uses a small subset of icons.

The generator should stop vendoring the entire Heroicons set and instead obtain Heroicons via git (so that the generated project does not commit/copy all icon SVG files into the project by default). A newly generated project should still work out of the box with the default UI/components that reference Heroicons, but the icons should be sourced as a git dependency rather than as a large set of vendored files.

Expected behavior:
- After running `mix phx.new <app_name>` with defaults, the generated project should not include a large vendored Heroicons directory containing the full icon library.
- The generated assets setup should fetch Heroicons from a git source during asset setup (so developers don’t need to store all SVGs in their own repo).
- Default generated components that use Heroicons should continue to function without requiring manual steps beyond the normal dependency/setup commands.

Actual behavior:
- `mix phx.new` produces a project where most of the on-disk size comes from vendored Heroicons, e.g. a multi-megabyte `assets/vendor/heroicons` directory.
- The generated release/container context includes those unused SVG files, increasing build artifacts unnecessarily.

Update the Phoenix project generator and its templates so Heroicons are pulled from git as part of the generated asset/dependency workflow, eliminating the large vendored icon payload while keeping the default generated UI working.