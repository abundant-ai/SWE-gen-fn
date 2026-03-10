`hledger add` currently rejects amounts that include balance assertions (eg `-15€ = 0`), printing an “A valid hledger amount is required …” validation error. As a result, users cannot use posting balance assertions while interactively adding transactions.

Update `hledger add` so that posting amounts may include balance assertions using the usual assertion syntax supported elsewhere in hledger, including both `=` and `==` forms (and assertion modifiers such as `==*`), and assertions appearing alongside other posting details (eg posting dates via comments like `; date:YYYY-MM-DD`).

When a user enters an amount with a balance assertion during `hledger add`, the command should accept the input as a valid amount and then verify the assertion against the running balance at that point in the transaction, using the same meaning as in normal journal parsing (eg whether subaccounts are included/excluded depending on the assertion operator/modifier). If the assertion holds, the flow should continue exactly as it does without an assertion.

If the assertion does not hold, `hledger add` should immediately alert the user and re-prompt for that same amount, pre-filling the previously entered text for convenience. The error should clearly identify the account whose assertion failed and show the asserted balance, the calculated balance, and the difference. Example interaction:

```
Amount  2 [$-15]: $-15 == $10

Balance assertion failed in Assets:Checking
Across all commodities at this point, excluding subaccounts, ignoring costs,
the asserted balance is:        $10
but the calculated balance is:   $5
(difference: $5)

Amount  2 [$-15]: $-15  == $5
```

The feature must work for:
- `==` assertions that fail and cause a re-prompt.
- `=` assertions that pass, including cases involving multiple commodities in the same account.
- Assertions that involve subaccount-sensitive behavior (eg `==*`).
- Transactions where postings include posting dates and multiple transactions are entered in one `add` session.

The final saved transaction should preserve the assertion text exactly as entered (other than whatever normal formatting `add` already applies), and successful assertion checks must not prevent saving the transaction.