Phoenix LiveView’s HEEx MacroComponent integration needs to support MacroComponent “directives”, specifically a root-tag attribute directive that can add attributes to the eventual root HTML element(s) produced by a template/component.

When a component implements the `Phoenix.Component.MacroComponent` behaviour and its `transform/2` callback returns a 4-tuple in the form:

```elixir
{:ok, new_ast_or_string, new_assigns_map, directives}
```

the compiler/runtime must process `directives` and apply any supported directives during rendering.

One supported directive is `:root_tag_attribute`. It may be returned multiple times. Each occurrence is a 2-tuple `{attr_name, attr_value}` where:

- `attr_name` is a string like `"phx-sample-one"`.
- `attr_value` is either:
  - a string (e.g. `"test"`), meaning the attribute should be rendered as `phx-sample-one="test"`, or
  - the boolean `true`, meaning the attribute should be rendered as a boolean attribute with no value (e.g. `phx-sample-one`).

In addition to MacroComponent-provided root tag attributes, the application environment can enable a global root tag attribute name via the `:phoenix_live_view` application env key `:root_tag_attribute` (e.g. `"phx-r"`). When configured, the engine must automatically apply this attribute to the appropriate root element(s) so the rendered HTML contains it in the expected places.

Currently, this directive/root-tag attribute behavior is missing or incomplete. As a result, templates that rely on MacroComponents returning `root_tag_attribute` directives (and/or templates rendered under a configured `:root_tag_attribute`) do not include the expected attributes on their root tags, or they fail during compilation/validation.

The implementation must ensure:

- `Phoenix.Component.MacroComponent.transform/2` may return directives in the 4-tuple form, and those directives are honored.
- Multiple `root_tag_attribute` directives can be returned and all must be applied.
- Both value-carrying attributes (`{"phx-sample-one", "test"}`) and boolean attributes (`{"phx-sample-one", true}`) are rendered correctly.
- Root tag attributes are applied correctly even when the relevant markup is inside nested constructs (conditionals, nested tags, inner blocks, and named slots).
- Directive validation is strict:
  - If a MacroComponent returns `root_tag_attribute: false` (or any non-`{name, value}` shape), compilation must fail with a `Phoenix.LiveView.TagEngine.Tokenizer.ParseError` explaining that the directive value is invalid.
  - If a MacroComponent returns any unknown directive key (for example `unknown: true`), compilation must fail with a `Phoenix.LiveView.TagEngine.Tokenizer.ParseError` indicating an unknown/unsupported directive.

This should work for both self-closing tags and tags with bodies, and it must not break existing MacroComponent behavior where `transform/2` only returns `{:ok, ast}`.