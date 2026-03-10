Some project-level configuration fields are being exposed/parsed with an unnecessary "project" prefix in their names (for example when decoding YAML into configuration monoids and when presenting/working with the aggregated Project configuration). This makes the effective field names inconsistent with the intended user-facing configuration keys and can cause confusion or mismatches when reading configuration values.

The configuration loading/parsing pipeline should treat Project field names as unprefixed, so that the logical names of Project fields match the keys users write in stack.yaml (and related config sources) without adding or expecting a "project" prefix.

In particular, when parsing project configuration via the Project/Config monoid layer, fields that belong to the Project configuration should be identified and represented without a leading "project" namespace/prefix. Loading a project configuration (via the usual configuration entry points such as loadConfig, loadConfigYaml, and the monoid parsers parseProjectAndConfigMonoid/parseConfigMonoid) should continue to succeed for typical stack.yaml content (e.g. specifying resolver, packages, build options, snapshot options, etc.), but the internal/project field names associated with Project should no longer be prefixed.

Expected behavior:
- Project field names are exposed/handled without a leading "project" prefix.
- Common stack.yaml configurations (resolver/packages and nested sections like build options) still parse correctly into the corresponding Config/Project structures.
- Any code that previously relied on prefixed Project field names (for lookups, warnings, or display) should be updated so that it works with the unprefixed names.

Actual behavior (before the fix):
- Project-related fields are named/handled with a "project" prefix, leading to inconsistent field naming and potential mismatches when interpreting configuration fields.

Update the relevant parsing and representation so that Project field names are unprefixed while keeping configuration loading behavior consistent and without introducing new warnings or parse failures for valid configurations.