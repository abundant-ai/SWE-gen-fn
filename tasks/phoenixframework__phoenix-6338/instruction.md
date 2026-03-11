Running Phoenix generators (notably `mix phx.gen.auth`, and similarly the HTML/JSON/Live generators that scaffold routes) currently injects an explicit route-name prefix into the router by adding an `as: :some_name` option to the `scope` macro they generate.

This behavior is outdated for modern Phoenix applications that use Verified Routes: `:as` is documented as having no effect with Verified Routes, and newly created projects no longer include `as:` on `scope`. The generated code therefore includes a deprecated/ineffective router option and suggests reliance on legacy Router Helpers naming.

Update the generator output so that the router snippet it produces does not add `as: ...` to `scope` for generated resources/auth routes. After the change, when a developer runs the generators in a modern Phoenix project, the inserted router code should use a plain `scope` without any `:as` option, relying on Verified Routes conventions. The generators should still produce valid route declarations and the rest of the generated application code should continue to compile and behave the same; only the deprecated route-name prefixing in the router should be removed.

Example of the problematic pattern that should no longer be generated:

```elixir
scope "/", MyAppWeb, as: :some_name do
  # generated routes
end
```

Expected generated pattern:

```elixir
scope "/", MyAppWeb do
  # generated routes
end
```
