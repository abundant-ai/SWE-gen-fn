When rendering templates through the controller or through endpoint error rendering, the assigns passed into the template are not always treated as a valid Phoenix.Component assigns map. In particular, calling `assign/3` inside an HEEx-based view (for example, a custom `ErrorHTML` module) can crash with:

`(ArgumentError) assign/3 expects a socket from Phoenix.LiveView/Phoenix.LiveComponent or an assigns map from Phoenix.Component as first argument ...`

This happens when a template render receives an assigns map that is missing the expected `__changed__` key (or has it in an unexpected shape), so Phoenix.Component does not recognize it as a component assigns map.

Rendering functions such as `Phoenix.Controller.render/3` (including template names given as strings like `"404.html"` or atoms like `:index`), and the error rendering used by `Phoenix.Endpoint.RenderErrors` should ensure the assigns passed to the view include `__changed__: nil` so they are compatible with Phoenix.Component and LiveView/HEEx expectations.

For example, a custom error page renderer like:

```elixir
def render("404.html" = template, assigns) do
  assigns = assign(assigns, message: "hello")

  ~H"""
  <h1><%= @status %> <%= @message %></h1>
  """
end
```

should render successfully, and `assign/3` should not raise. The assigns delivered to error views for formats like HTML and JSON must include `__changed__: nil` alongside keys such as `:kind`, `:reason`, `:stack`, `:status`, and `:conn`.

Expected behavior: controller renders and endpoint error renders provide assigns maps that are valid Phoenix.Component assigns (including `__changed__: nil`), so `assign/3` can be used in error templates and other HEEx templates.

Actual behavior: attempting to call `assign/3` in these renders can raise an `ArgumentError` because the assigns are not recognized as a Phoenix.Component assigns map.