Ecto query hints currently allow potentially unsafe forms: a `literal(...)` helper and keyword-list (KW) hint values. These forms make it too easy to inject raw SQL as part of a `from` hint.

Update the query API so that `literal(...)` is deprecated in favor of `unsafe_literal(...)` (same behavior, new name), and so that dynamic hints no longer accept keyword-list entries. Instead, hints must be expressed as a list of tokens where any dynamic SQL part is wrapped using an unsafe helper.

Concretely:

When building a query with `from/2` using the `:hints` option, Ecto should support hints like:

```elixir
from(p in "posts", hints: ["SAMPLE", unsafe_literal("bernoulli"), "(10)"])
```

and should treat this as the mechanism for any SQL that comes after `FROM` (such as sampling methods that may vary by database/extension).

At the same time, the older hint forms should be rejected or warned about:

1) Using `literal("...")` should emit a deprecation warning instructing users to use `unsafe_literal("...")` instead, without changing the produced query expression.

2) Using keyword hints (for example forms like `hints: [sample: ...]` or other KW entries inside `:hints`) should no longer be accepted for dynamic content. Users must rewrite them into the token-list form and use `unsafe_literal/1` (or `unsafe_fragment/1` where appropriate) for any non-static SQL parts.

The expected result is that query building succeeds for the token-list form (including dynamic/extension-provided sampling methods) while steering users away from the older `literal` name and unsafe KW hint values. Any compilation/runtime errors or warnings raised should clearly describe what form is unsupported and how to migrate (use `unsafe_literal` and tokenized hints).