Running Dialyzer on Elixir 1.19.x reports false-positive “The function call will not succeed” warnings for valid uses of `Code.format_string!/2` when passing documented formatting options.

For example, calling:

```elixir
Code.format_string!("", line_length: 120, force_do_end_blocks: true)
```

incorrectly triggers a Dialyzer error like:

```
The function call will not succeed.

Code.format_string!(<<>>, [{:line_length, 120}, {:force_do_end_blocks, true}])

will never return since the 2nd arguments differ
from the success typing arguments: ...
```

This is a regression compared to Elixir 1.18.x, where the same call produced no Dialyzer warnings. The API is not intended to have changed: `:line_length` and `:force_do_end_blocks` (as well as other documented options such as `:locals_without_parens` and `:migrate`) are valid formatting options.

`Code.format_string!/2` should accept a keyword list of formatting options without Dialyzer concluding the call cannot succeed. Dialyzer should not reject keyword lists that include valid keys/values from the documented formatting options type; these calls should be considered reachable and should not produce warnings during analysis.