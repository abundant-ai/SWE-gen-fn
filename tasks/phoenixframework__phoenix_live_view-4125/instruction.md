Macro component directives and colocated script handling in HEEx need to work with a full, upfront tag tree rather than incremental open/close tag handling.

Currently, using the `:type` directive on tags to invoke a macro component (a module implementing `Phoenix.Component.MacroComponent`) should provide that component with the complete element AST (tag name, attributes, children, and closing metadata) plus compilation metadata, and allow the macro component to replace the AST that will be rendered. The AST must preserve text nodes (including whitespace/newlines) and must correctly represent void/self-closing elements and nested structures like SVG.

When a macro component module defines `transform(ast, meta)`, it should be called with:

- `ast` shaped like `{tag_name, attrs, children, meta_map}` where:
  - `tag_name` is a string like `"div"`.
  - `attrs` is a list of `{name, value}` pairs where static attributes use literal strings (for example `{"id", "1"}`) and dynamic HEEx expressions are represented as quoted AST (for example `{"other", {:@, _, [{:foo, _, nil}]}}` corresponding to `other={@foo}`).
  - `children` is a list containing both text nodes (strings) and nested element tuples.
  - `meta_map` includes closing information for tags that are `:void` or `:self` closed (for example `%{closing: :void}` for `<hr>` and `%{closing: :self}` for `<circle ... />`).
- `meta` that includes an `env` with the caller module and file (so `meta.env.module` matches the component module being compiled and `meta.env.file` matches the source file).

Expected behavior:

1) A macro component receives the full AST for an element written like:

```elixir
~H"""
<div :type={MyComponent} id="1" other={@foo}>
  <p>This is some inner content</p>
  <h1>Cool</h1>
  <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
    <circle cx="50" cy="50" r="50" />
  </svg>
  <hr />
</div>
"""
```

and the AST must include the nested `p`, `h1`, `svg`, `circle` (self closing), and `hr` (void) with the correct attribute values and closing metadata.

2) If `transform/2` returns `{:ok, new_ast}`, the engine must render `new_ast` instead of the original element, including supporting dynamic attribute expressions inside `new_ast` (for example `{"id", quote(do: @foo)}`) and mixing elements and text content.

3) Colocated script extraction via `<script :type={Phoenix.LiveView.ColocatedJS} ...>` and `<script :type={Phoenix.LiveView.ColocatedHook} ...>` must continue to work while using the same tree-based compilation approach:

- For colocated JS, a script like:

```elixir
~H"""
<script :type={Colo} name="my-script">
  export default function() {
    console.log("hey!")
  }
</script>
"""
```

must be extracted to a `.js` file whose contents preserve the JS body text (including leading/trailing newlines/indentation as emitted by the template engine), and later be included in a generated manifest that maps the `name` to an exported module reference.

- For colocated hooks, using `name=".fun"` should generate a JS file containing the hook implementation and the manifest must export hooks appropriately.

- If the `name` attribute for a colocated hook is not a compile-time string (for example `name={@foo}`), compilation must raise `Phoenix.LiveView.TagEngine.Tokenizer.ParseError` with an error message matching:

`the name attribute of a colocated hook must be a compile-time string. Got: @foo`

Implement/fix the TagEngine compilation so that macro components, tag closing semantics, and colocated JS/hook extraction all behave as described when compiling HEEx templates using the refactored tree-based compiler approach.