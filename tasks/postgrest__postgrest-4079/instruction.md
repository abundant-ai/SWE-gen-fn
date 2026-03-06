PostgREST currently treats certain string configuration values that are explicitly set to the empty string ("") as if they were not set, which causes them to fall back to defaults and/or triggers confusing parse failures. This shows up most visibly with schema/search-path related settings.

When configuring PostgREST with environment variables (or equivalent config sources), setting the “extra search path” to an explicit empty value should be accepted and preserved as empty, rather than being rejected by parsing or silently replaced with a default.

Reproduction:
- Configure PostgREST to connect to a database that does not have a `public` schema (or where `public` should not be used).
- Start PostgREST with the extra search-path setting explicitly set to an empty string, e.g. `PGRST_DB_EXTRA_SEARCH_PATH=""`.

Actual behavior:
- PostgREST fails to start due to a configuration parsing error when the value is ""; or, in cases where empty strings are filtered out earlier, PostgREST behaves as if the setting was not provided and falls back to a default such as `public`, which then breaks startup or makes only `public` appear in the exposed API.

Expected behavior:
- Explicitly setting the extra search-path to "" must be allowed.
- An explicitly empty value must not be dropped/filtered and must not be replaced by the default value.
- With `PGRST_DB_EXTRA_SEARCH_PATH=""`, PostgREST should start successfully and behave as if no extra schemas were added to the search_path beyond what is implied by the primary schema configuration.

Additionally, configuration handling should distinguish between “unset” and “explicitly set to empty string” for relevant string settings so that users can intentionally clear values without triggering defaults that change behavior.

Implement the necessary changes in the configuration parsing/normalization logic so that these empty-string cases no longer cause parse errors and are not coerced back to defaults.