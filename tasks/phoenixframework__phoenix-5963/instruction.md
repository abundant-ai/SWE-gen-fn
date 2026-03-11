When using Phoenix’s code generators to scaffold resources, fields declared with the Ecto type `:text` are currently rendered in the generated forms as a single-line text input. This is inconsistent with the intent of `:text` (typically multi-line content) and results in generated HTML that is awkward for editing larger bodies of text.

Reproduction: run the generators for a resource that includes a `content:text` (or any `:text`) attribute, for example:

```elixir
Mix.Tasks.Phx.Gen.Html.run(["Blog", "Post", "posts", "title:string", "content:text"])
Mix.Tasks.Phx.Gen.Live.run(["Blog", "Post", "posts", "title:string", "content:text"])
```

Expected behavior: the generated form should render `:text` fields using a multi-line textarea component (i.e., using the textarea form helper/component rather than an `<input type="text">`-style control). This should apply consistently to both the HTML generator and the LiveView generator.

Actual behavior: the generated form renders `:text` fields as a standard single-line text input.

Update the generators so that `:text` maps to a textarea in generated form templates while keeping existing behavior for other field types unchanged.