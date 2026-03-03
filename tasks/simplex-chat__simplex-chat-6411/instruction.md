Chat relay links have recently changed type, but the core chat/servers logic is not consistently handling the new relay link representation across the operator/server management flow. As a result, operations that validate and update user-provided servers and chat relay configurations can mis-handle relay addresses (e.g., treating distinct relays as duplicates, failing to detect duplicates, or failing to validate presence/absence of chat relays), and may also fail to encode/decode relay links in the expected format.

The server/operator management API should correctly support the new relay link type end-to-end. In particular:

- `validateUserServers` must accept valid user server configurations that include chat relays expressed using the new relay link type, and it must continue to produce the correct validation errors/warnings for invalid configurations.
- Duplicate detection must work with the new relay link type:
  - Duplicate relay *names* must be detected and reported as `USEDuplicateChatRelayName <name>`.
  - Duplicate relay *addresses* must be detected and reported as `USEDuplicateChatRelayAddress <name> <address>` where `<address>` is the canonical textual form of the relay link.
- Missing/disabled server scenarios must continue to behave the same, including:
  - Reporting `USENoServers` when no usable servers exist for required roles.
  - Reporting `USEStorageMissing` when storage role is required but missing.
  - Emitting `USWNoChatRelays` as a warning when chat relays are absent/disabled in situations where they are expected.

Additionally, any code that serializes or parses relay links (for example when reading presets, user config, or persisted entities) must be updated so that relay links round-trip correctly using the new type. A relay link should have a stable canonical string representation used for equality/duplicate checks and for displaying in error messages.

If currently calling `validateUserServers` with configurations containing chat relays causes mismatched validation results (wrong error/warning constructors, wrong address strings, or missing duplicate detection), update the core logic so the returned lists of errors and warnings match the intended behavior above under the new relay link type.