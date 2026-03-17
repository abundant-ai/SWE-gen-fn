In IEx, when an entered expression raises (or is rejected during expansion) and the next prompt begins with a piping operator (for example `|>` or other “arrow”/pipe-like operators), the new input can be unintentionally treated as a continuation of the previous, failed expression. This is dangerous because a user may paste a multi-line pipeline, hit a syntax error early (such as a mismatched bracket inside a function call), and then have subsequent `|> ...` lines evaluated in an unintended way, potentially running side-effecting calls.

IEx should detect when the last evaluated expression resulted in an error, and if the next input begins with an “arrow op” (i.e., starts an expression with a pipe/arrow operator rather than a normal expression), IEx must refuse to evaluate it. Instead, it should print a warning that evaluation is being skipped for safety, echo the skipped input, and explain that beginning an expression with an arrow operator is not allowed immediately after an error.

Reproduction example:

1) Cause an error (any compile/expand/runtime error in IEx is sufficient).
2) On the next prompt, enter a line starting with a pipe, such as:

```elixir
|> Kernel.+(1)
```

Expected behavior: IEx does not evaluate the expression at all, prints a message indicating evaluation was skipped, prints the skipped code, and includes a safety explanation that you cannot begin an expression with an `arrow_op` when the last expression was an error.

Actual behavior: IEx proceeds to evaluate (or attempt to evaluate) the piped expression after an error, which can lead to unintended execution.

This safety check must apply to interactive input handling (the normal IEx prompt flow), and it must not break normal valid pipelines that start with a regular expression (e.g. `some_value |> f()`), only the case where the user begins the new input with the arrow operator after an error.