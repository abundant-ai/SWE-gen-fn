When building changesets for embedded schemas, association helpers like `Ecto.Changeset.cast_assoc/3`, `Ecto.Changeset.put_assoc/4`, and related helpers currently raise `ArgumentError` in situations where the association is being cast/put inside an embedded schema changeset. This behavior is new compared to earlier versions and breaks workflows where an embedded schema changeset is responsible for managing associations on the embedded struct.

Reproduction example (simplified): define a schema with a `belongs_to` association and a changeset that calls `cast_assoc(:profile)` (or uses `put_assoc/4` to set the associated struct). When this changeset is invoked as part of casting an embed (i.e., the association logic runs from within an embedded schema changeset), the call raises `ArgumentError` instead of producing an association changeset or a validation error.

Expected behavior: inside embedded schema changesets, `cast_assoc/3` and `put_assoc/4` should be able to cast/put associations in the same way they do for non-embedded schemas. For valid nested params (for example `%{"profile" => %{"name" => "michal"}}` on a `belongs_to :profile`), the parent changeset should contain an associated changeset under `changes.profile` with:

- `action` set appropriately (`:insert` when there is no existing associated struct; `:update` when an existing associated struct with matching id is present)
- `changes` populated from params (e.g. `%{name: "michal"}`)
- `errors` empty and `valid?` true when the associated changeset is valid

For invalid nested params, it should not crash; it should either:

- produce an invalid associated changeset (e.g. missing required `:name` yields an error like `name: {"can't be blank", [validation: :required]}`), causing the parent changeset to be invalid, or
- add an association validation error on the parent changeset for incorrect types (for example when the nested value is not a map, an error like `profile: {"is invalid", [validation: :assoc, type: :map]}` should be added).

Actual behavior: the above scenarios raise `ArgumentError` when invoked within embedded schema changesets.

Fix the association casting/putting logic so that associations can be cast/put from within embedded schema changesets without raising `ArgumentError`, and so that the resulting changesets and errors match the behaviors described above.