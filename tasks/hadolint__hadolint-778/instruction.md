Hadolint’s environment-based configuration currently interprets the `NO_COLOR` environment variable based on its value (e.g., treating values like `n` or an empty string as meaning “don’t disable colors”). This conflicts with the NO_COLOR specification (https://no-color.org), which states that the value is irrelevant: if `NO_COLOR` is present in the environment, colored output must be disabled.

When calling `getConfigFromEnvironment`, the resulting config should set `partialNoColor = Just True` whenever `NO_COLOR` is set in the environment, regardless of whether it is set to "true", "false", "y", "n", or even an empty string (""), as long as the platform supports setting an environment variable to an empty string.

Expected behavior:
- If `NO_COLOR` is set to any value (including `"y"`, `"n"`, or `""`), `getConfigFromEnvironment` should treat it as enabling “no color” and produce a config where `partialNoColor` is `Just True`.
- If `NO_COLOR` is not set at all, `getConfigFromEnvironment` should leave `partialNoColor` as `Nothing`.

User-visible reproduction:
- `NO_COLOR= hadolint Dockerfile` should produce uncolored output (same as `NO_COLOR=true hadolint Dockerfile` and `NO_COLOR=n hadolint Dockerfile`).
- `unset NO_COLOR; hadolint Dockerfile` should allow colored output (assuming no other flags/config disable it).

This should be implemented by adjusting the environment parsing logic so that it checks for the presence of `NO_COLOR` rather than parsing/inspecting its value.