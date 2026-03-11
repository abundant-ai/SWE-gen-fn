When using associations inside an embedded schema, the association field can incorrectly remain as an %Ecto.Changeset{} after persisting the parent struct, instead of becoming the associated schema struct.

Reproduction scenario:

- Define a schema A that embeds_one :b, B
- Define embedded schema B that has belongs_to :c, C
- Build a changeset for A using Ecto.Changeset.cast_embed/3 for :b
- Inside B’s changeset, set the association using Ecto.Changeset.put_assoc/3 (or by calling Ecto.Changeset.put_change/3 on the association field)
- Insert A via Repo.insert/2

Actual behavior:

After Repo.insert/2 succeeds, the resulting struct has the embedded association field set to a changeset, e.g.:

    {:ok, %A{b: %B{c: %Ecto.Changeset{...}}}}

This is incorrect because the association should not be represented as a changeset in the persisted result.

Expected behavior:

After Repo.insert/2 (or otherwise applying changes), the embedded schema’s belongs_to association should resolve to the associated struct (or nil), e.g.:

    {:ok, %A{b: %B{c: %C{...}}}}

Required behavior changes:

- Associations declared inside embedded schemas must be treated as read-only with respect to persistence in embeds.
- Ecto.Changeset.put_assoc/3 and Ecto.Changeset.cast_assoc/3 should not allow embedding an association change that later leaks as an %Ecto.Changeset{} into the embedded struct.
- If a user attempts to cast or put an association on an embedded schema (for example, a belongs_to inside embedded_schema), the behavior must be consistent and explicit: either the operation is rejected with a clear ArgumentError explaining that associations in embeds are read-only, or it is ignored in a way that does not produce a changeset value in the resulting struct.

The fix should ensure that working with embeds does not produce persisted structs containing %Ecto.Changeset{} values for association fields, and that the error/behavior is clear when attempting to modify such associations via changesets.