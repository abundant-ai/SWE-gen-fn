The schema generator can behave nondeterministically depending on map iteration order, causing random/flaky results when building schema metadata from command-line attribute arguments.

When calling `Mix.Tasks.Phx.Gen.Schema.build/2` with a list of field specs, the returned `%Mix.Phoenix.Schema{}` should be deterministic: fields should preserve the input order for `attrs`, and any derived structures (such as `types`, `defaults`, and `migration_defaults`) should be built in a way that does not rely on the iteration order of a map.

A reproducible example is building a schema with multiple string fields, such as:

```elixir
schema = Mix.Tasks.Phx.Gen.Schema.build(~w(Blog.Post posts title:string desc:string), [])
```

Expected behavior: repeated calls (including repeated runs of the test suite) should always yield the same `%Mix.Phoenix.Schema{}` content. In particular, `schema.attrs` should remain in the same order as provided (`[title: :string, desc: :string]`), and `schema.types` should consistently reflect those fields without sometimes swapping order or otherwise changing between runs.

Actual behavior: running the same operation repeatedly can sometimes produce a schema where derived ordering-dependent values differ run-to-run (for example, the ordering of `attrs`/`types`, and any downstream defaults/params that depend on the “first” field), leading to intermittent assertion failures in downstream usage.

Fix `Mix.Tasks.Phx.Gen.Schema.build/2` (and any shared generator helpers it relies on, such as default type/default value computation) so that default type selection and any other schema derivations do not depend on map ordering and are stable across runs and across different command-line argument orderings.