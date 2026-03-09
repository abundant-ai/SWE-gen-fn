Cram tests currently always default to being attached to the standard `@runtest` alias unless explicitly configured via the existing `alias` field. This makes it impossible to define a cram test that should only run under a custom alias without also running under `dune runtest`.

Add support for configuring the default alias attachment for a cram test via a new field `runtest_alias` (also described as allowing overriding the default alias). The behavior should be:

When a cram stanza is configured with `(runtest_alias false)` and also has `(alias this)`, running `dune runtest` must NOT run the cram test, but running `dune build @this` must run it.

If the default runtest alias attachment is not configured for a cram test, the default behavior must remain unchanged (the test is attached to `@runtest`).

It must be an error to set `runtest_alias` more than once for the same cram test (even across multiple cram stanzas affecting the same test). When this happens, Dune should fail with an error message stating that enabling or disabling the runtest alias for a cram test may only be set once, and it must also indicate that it was already set for the test (e.g., by naming the test like "foo") and point to the location of the first definition. The location of the second (conflicting) definition should be highlighted as the primary error span.

The implementation should ensure that the alias graph produced for cram tests respects `runtest_alias` so that `@runtest` inclusion is truly controlled by this setting rather than only by additional aliases.