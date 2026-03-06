Hadolint’s configuration file auto-discovery is not behaving in a backwards-compatible way and does not match the documented search paths. As a result, running hadolint with no explicit config path can fail to pick up an existing config file (or may pick up the wrong one), depending on where the config file is located.

The config discovery logic should be updated so that it is backwards compatible with older hadolint behavior while also matching the documented config file locations. In particular, when hadolint is executed, it should search for a configuration file in the expected locations in the correct precedence order (including legacy locations), and stop at the first match. If both a legacy path and a newer documented path exist, the intended precedence must be applied consistently so that users get predictable results.

Fix the behavior so that:

- If a config file exists in a legacy location that older versions would have found, hadolint still finds and uses it when no explicit config file is provided.
- If a config file exists in the newly documented location(s), hadolint finds and uses it as documented.
- When multiple candidate config files exist, the selection is deterministic and matches the documented precedence.
- Supplying an explicit config path continues to override auto-discovery.

After the change, hadolint should correctly load configuration based on these search rules and no longer require users to move/rename configs to make them discoverable.