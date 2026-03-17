PostgREST currently supports a configuration setting named `db-embed-default-join` that controls what kind of join is used by default when clients request embedded resources. This option needs to be removed completely.

At the moment, users can set `db-embed-default-join` in the configuration and it affects how embedding behaves (e.g., whether embedding defaults to an inner join vs the existing default behavior). After this change, PostgREST must no longer recognize `db-embed-default-join` as a valid configuration key from any supported config source, and embedding behavior must no longer depend on it.

The expected behavior after the fix:

- If a configuration contains `db-embed-default-join`, PostgREST should not accept it as a supported setting. It should either fail fast with a clear configuration error indicating the option is unknown/unsupported, or otherwise ensure the option has no effect and is not shown as part of the effective configuration.
- The effective configuration output/representation must not include `db-embed-default-join` anymore under any circumstances (including when printing defaults or normalized configs).
- Embedding behavior must be consistent and deterministic without this setting. Requests that embed related resources must use the single supported default join behavior across the system.

Reproduction example (behavioral):

1) Start PostgREST with a config that includes `db-embed-default-join` (for example setting it to request inner join by default).
2) Make an API request that embeds a related resource (for example `GET /parent?select=*,child(*)`).

Currently, the join semantics can change based on `db-embed-default-join`. After the fix, the service must not allow controlling default embedding join semantics via configuration, and the response semantics must match the fixed default behavior.

Also ensure that configuration normalization/printing behaves correctly for booleans, numbers, strings, aliases, and default/no-default setups: the produced effective config must match the supported keys list and must exclude `db-embed-default-join` entirely.