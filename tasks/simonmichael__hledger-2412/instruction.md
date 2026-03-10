Auto-posting rules should support referring to the account name of the posting that matched the rule. Currently, when an auto-posting rule generates postings, there is no way to reuse the matched posting’s account name inside the generated posting’s account field, forcing users to duplicate rules for many accounts.

Implement support for a special placeholder string `%account` within the account name specified in an auto-posting rule. When a posting matches a rule, any generated posting whose account contains `%account` must have that substring replaced with the full account name of the matched posting (the posting that triggered the rule). This substitution should work when `%account` appears as the entire account name (eg `%account`) and also when embedded within a larger account expression (eg `(Budget:%account)` or `Income:%account:VAT`).

Example use case: a rule matching income postings with a `tax` tag needs to split VAT by generating two postings, one of which modifies the original income amount by posting back to the same income account. With `%account` support, a rule like:

```
= acct:Income tag:tax=19%
  %account         *-0.15966387
  Liabilities:VAT  *0.15966387
```

should generate postings that apply to whatever specific `Income:...` account matched, without writing separate rules for each income account.

Expected behavior:
- Running commands that apply auto-posting rules (eg printing/registering/balancing with auto rules enabled) should insert generated postings that use the substituted account name.
- The substitution should use the matched posting’s account exactly as it appears in the journal (full account path), including any subaccounts.
- Substitution must occur before the generated posting is inserted/processed so that downstream processing (display, balancing, assertions, and any rule metadata like generated-posting annotations) sees the final expanded account name.

Actual behavior to fix:
- `%account` is treated as a literal string in the generated posting’s account, so generated postings end up posted to an account literally named `%account` (or containing it) instead of the matched posting’s account.

After the change, `%account` should reliably resolve to the matched posting’s account name everywhere auto-posting rules can specify an account for generated postings.