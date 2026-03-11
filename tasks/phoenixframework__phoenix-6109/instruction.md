Phoenix project generators are being updated to support Tailwind CSS v4, but generated projects are not consistently configured to work correctly with the new Tailwind setup.

When creating new projects via the installer Mix tasks, the generated asset configuration must be updated so the Tailwind integration is correct and stable across all supported generation modes (single app, umbrella app, and web-only app inside an umbrella).

The problems to address are:

1) Generated Tailwind config files must correctly reference app-specific paths and dependencies.
For a newly generated web app inside an umbrella, the generated Tailwind heroicons integration file must include a correct reference to the heroicons optimized assets under the project’s deps directory (for example it must contain a path segment like "/deps/heroicons/optimized"). This should be true regardless of the chosen app name.

2) Umbrella and web-only generation must properly update shared configuration behavior.
When running the web-only generator inside an umbrella (creating an app like "testweb" under apps/), the umbrella root configuration must end up importing environment-specific config via:

import_config "#{config_env()}.exs"

If the umbrella root config previously lacked that import (for example, in a minimal/barebones umbrella setup), running the web generator should add it back so the resulting umbrella config behaves like a standard Phoenix umbrella configuration.

3) The web-only generator must enforce correct usage context.
Running Mix.Tasks.Phx.New.Web.run/1 outside an umbrella’s apps directory must raise a Mix.Error with a message indicating the web task can only be run within an umbrella’s apps directory.

Expected behavior: running Mix.Tasks.Phx.New.run/1, Mix.Tasks.Phx.New.Umbrella, and Mix.Tasks.Phx.New.Web.run/1 should produce projects whose asset pipeline and Tailwind-related generated files match the new Tailwind v4 expectations, including correct heroicons path wiring and correct umbrella root config imports.

Actual behavior: generated Tailwind-related configuration and/or umbrella config import behavior is incorrect or inconsistent after the Tailwind v4 generator update, causing generated projects (especially umbrella/web-only) to be misconfigured.