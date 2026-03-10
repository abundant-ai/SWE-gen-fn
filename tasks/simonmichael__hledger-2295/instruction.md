When exporting a journal using `hledger print -O beancount`, the output is often rejected by Beancount’s `bean-check` due to several incompatibilities that currently require manual cleanup. The Beancount output mode should be made robust enough that it automatically performs the necessary adjustments so the resulting Beancount journal is accepted by `bean-check`, except for the one remaining manual prerequisite: top-level account names must already be Beancount’s required roots (`Assets`, `Liabilities`, `Equity`, `Income`, `Expenses`) or be rewritten by the user via aliases.

Currently, the Beancount exporter does not consistently enforce/transform all of these rules, causing invalid output or requiring tedious post-processing. Implement the following behavior for `print -O beancount`:

1) Reject unknown top-level account names. If any posting account’s top-level name is not one of `Assets`, `Liabilities`, `Equity`, `Income`, `Expenses` (case-insensitive input is ok, but it must map to one of these), the command should fail with an error message that matches the idea of “bad top-level account”.

2) Normalize/encode account names into valid Beancount account names and emit `open` directives. For each account that appears in postings, the exporter should:
- Capitalize each account name part.
- Replace spaces with `-`.
- Replace other unsupported characters with `C<HEXBYTES>`-style encodings (eg `$` and `€` should become encoded forms in the account name).
- If an account name has only one part (eg `Assets`), append a second part (eg `:A`) so it becomes a valid multi-part Beancount account name.
- For any account name part that does not begin with a letter or digit, prepend `A`.
The output should include `open` directives dated on the transaction date for each encountered account before the transactions that use them.

3) Normalize/encode commodity symbols into valid Beancount commodities. Examples of expected conversions:
- Currency symbol `$` should become `USD`.
- A bare commodity symbol like `0` should produce a valid commodity name (eg `C`).
- `!` or other punctuation-only commodities should be encoded (eg `C21` for `!`).
- Quoted commodity names like "size 2 pencils" should become a valid uppercase dashed commodity like `SIZE-2-PENCILS`.

4) Remove virtual postings automatically. Postings to virtual accounts (eg parenthesized `(a)` or bracketed `[b]`) must be dropped from the Beancount output rather than rendered, so that the transaction remains Beancount-valid.

5) Preserve non-redundant conversion postings. If a transaction uses explicit conversion postings (eg postings to an `equity:conversion:...` account) and they are not redundant with costs, they should remain in the output and their accounts should be normalized the same way as all other accounts.

6) Drop redundant conversion postings when costs are present, and emit operating currencies. If a transaction contains costs (eg an amount like `1 USD @@ 1 EUR`), and the same transaction also contains explicit conversion postings that merely restate that conversion, those conversion postings should be removed from the Beancount output. Additionally, for each distinct cost currency encountered in the exported data, emit an `option "operating_currency" "<CUR>"` directive (eg `option "operating_currency" "EUR"`) so the produced Beancount file declares the currencies implied by costs.

7) Error on multiple cost/conversion groups within a single transaction. If a single transaction contains more than one independent cost/conversion grouping (eg two separate sets of costed postings implying separate conversions), the exporter should fail rather than emit ambiguous/incorrect Beancount. The error should indicate the transaction is unbalanced (or otherwise clearly invalid).

8) Convert tags to Beancount metadata. hledger tags present on transactions/postings should be rendered as Beancount metadata lines (the `key: "value"`-style metadata syntax). However, account tags should not be added to postings in the Beancount output (avoid introducing extra metadata derived from account-level tags when rendering postings).

The goal is that running `hledger print -O beancount` on typical hledger journals produces Beancount syntax that passes `bean-check` without manual removal of virtual postings, hand-editing invalid account/commodity names, or manually deleting redundant conversion postings; only top-level account naming remains a user responsibility.