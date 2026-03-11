The `hledger register` command currently prints postings in date order and does not support sorting by other criteria. Users need a `--sort` (alias `-S`) option similar to `ledger register --sort`, allowing register output to be ordered by one or more value-expressions.

When running `hledger register --sort <expr>` the command should sort postings by evaluating `<expr>` for each posting and ordering accordingly. The `<expr>` argument must accept a comma-separated list of expressions, applying each term as a tie-breaker in sequence (eg `account,amount`). Each term may be prefixed with `-` to reverse the sort direction for that term (eg `-date`, or `amount,-account`).

Supported sort expressions must include at least:
- `date` (posting/transaction date)
- `account` (posting account name)
- `amount` (posting amount)
- `absamount` (absolute value of posting amount)
- `desc` (transaction description)

Expected behavior examples:
- Given postings across multiple dates and accounts, `hledger -f - register --sort account` should group/order output by account name rather than by date.
- `hledger -f - register --sort account,amount` should sort primarily by account, and within the same account by amount.
- `hledger -f - register --sort -account` should reverse the account ordering.
- `hledger -f - register --sort amount,-account` should sort by amount ascending, and when amounts are equal, by account descending.
- `hledger -f - register --sort -date` should produce reverse chronological order.
- `hledger -f - register --sort desc` should order by transaction description.

The running balance column must be recalculated to match the new posting order (it should be the cumulative sum in the displayed order, not the original chronological order).

If `--sort` is not provided, the existing behavior (date-ordered register output) should remain unchanged. The option should also work consistently for closely related register-style reports (eg the account-register variant) if they share the same underlying postings report generation.