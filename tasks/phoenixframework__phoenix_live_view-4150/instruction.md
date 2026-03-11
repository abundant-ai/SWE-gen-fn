LiveView’s HEEx (~H) template compilation incorrectly treats EEx comments (`<%!-- ... --%>`) as meaningful content when determining the root static HTML element for stateful live components. This can cause valid component templates to raise an error about the root element even though comments should be ignored.

Reproduction example:

```elixir
def render(assigns) do
  ~H"""
  <%!-- This comment gives an error <div class=\"flex justify-center\"> --%>
  <div class="flex justify-center">
  </div>
  """
end
```

Actual behavior: compiling/rendering the component raises an `ArgumentError` similar to:

```
(ArgumentError) error on ...render/1 with id of "nuts". Stateful components must have a single static HTML tag at the root
```

Expected behavior: EEx comments are ignored during parsing/compilation, so a comment before the first static HTML element must not affect root tracking. The example above should compile and render normally without triggering the “single static HTML tag at the root” error.

Implement support in the LiveView template compilation pipeline so that EEx comments (`<%!-- ... --%>`) are stripped/omitted early enough (during tokenization/parsing for `Phoenix.LiveView.TagEngine.compile/2` with `Phoenix.LiveView.HTMLEngine`) that they do not participate in root static tag detection or any structural validations.