hledger currently supports account types (with short codes like A/L/E/R/X) and also supports subtype behavior for certain types (eg Cash as a subtype of Asset, Conversion as a subtype of Equity). A new account type is needed to support tracking capital gains/losses separately while still behaving like Revenue for reports and operations that include revenue accounts.

Implement a new account type named "Gains" with the single-letter code "G". Gains must be treated as a subtype of Revenue.

Users should be able to declare it on accounts using either short or long form, eg:

```journal
account revenues:capital  ; type: G
```

Required behavior:

- Type parsing and display must recognize Gains as a valid account type, with code `G` and name `Gains`.
- Type-based queries using `type:` must support Gains:
  - `type:G` matches only Gains accounts.
  - `type:R` matches both Revenue accounts and Gains accounts (because Gains is a subtype of Revenue).
  - Type-code matching must remain case-insensitive, and order-independent when multiple codes are provided (eg `type:rg` should work like `type:GR`).
  - Matching should work consistently whether the account is declared (`--declared`), used (`--used`), or appears in postings/transactions (eg in register/print reports).
- Income statement classification must treat Gains as an income-statement account type, and Gains accounts must appear under the Revenues section of income statement reports (not in a separate section).
- The close command behavior must include Gains in retained-earnings closing when using `hledger close --retain`. In other words, when `--retain` closes revenue and expense activity into equity, Gains activity must be included along with Revenue (via subtype matching).

Currently, attempts to use `type:G` should be expected to fail (unknown type or no matches), and `type:R` likely does not include Gains. After implementing Gains and its inheritance, the above commands and reports should behave as described.