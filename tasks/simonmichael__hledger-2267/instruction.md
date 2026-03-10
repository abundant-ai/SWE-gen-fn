When running strict checks on a journal that uses multi-commodity transactions and price annotations, hledger 1.40+ can fail `check accounts` (and related strict checks) because `--infer-equity` introduces implicit conversion postings that reference automatically generated conversion accounts (for example `equity:conversion:CD200130-MXN:CD200130`). These inferred account names include commodity symbols and are not declared by the user, so strict account checking raises an error like:

"Strict account checking is enabled, and account \"equity:conversion:CD200130-MXN:CD200130\" has not been declared. Consider adding an account directive."

This is a regression for users who previously could run `hledger check -s` successfully on the same journals.

Fix hledger so that using `--infer-equity` does not force users to predeclare all inferred conversion accounts just to satisfy strict account checking. Specifically:

1) `check accounts` should not warn/error for conversion accounts that are generated/used for equity conversions (eg accounts under `equity:conversion` and other conversion base accounts used by equity conversion inference), including their subaccounts created to represent commodity pairs and commodities.

2) Account type detection should treat certain well-known names as conversion accounts by default: `equity:conversion`, `equity:trade`, `equity:trades`, and `equity:trading` should be detected as type `V` (Conversion) when showing account types.

3) However, if the user declares some other account with type `V`, then those default names (`equity:conversion`, `equity:trade`, `equity:trades`, `equity:trading`) should no longer be considered special conversion accounts; they should instead be treated as ordinary equity accounts (type `E`).

4) `--infer-equity` should use `equity:conversion` as its base conversion account by default, and if the user declares a custom conversion account (type `V`, eg `account trade  ; type:V`), `--infer-equity` should use that declared conversion account as the base instead. In that case, the inferred accounts should be rooted at the custom conversion account (eg `trade:A-B:A` and `trade:A-B:B` instead of `equity:conversion:A-B:A` and `equity:conversion:A-B:B`).

After this change, a journal containing a transaction like:

- posting in one commodity with an `@` price in another commodity
- balancing posting to another asset account

should be able to pass `hledger check -s` / `hledger check accounts` without requiring manual `account ...` directives for the inferred conversion accounts.

Implement the behavior by adjusting the logic that (a) detects cost/conversion postings, (b) determines account types (notably `journalAccountTypes`), and (c) decides which accounts are subject to strict account checking.