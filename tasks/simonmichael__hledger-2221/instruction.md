Periodic transaction forecasting and report interval generation can produce dates that occur before the user-specified start date.

When a periodic rule uses an “every Nth day (of month)” pattern with an explicit start date, occurrences must not be generated earlier than that start date. Currently, rules like the following can incorrectly generate an extra occurrence prior to the declared start:

```journal
~ every 31st day from 2024-07 to 2024-09
  (a)  1
```

Running a forecasted report (eg, `hledger print --forecast=2024` or `hledger register --forecast=2024`) should only generate occurrences on `2024-07-31` and `2024-08-31` (and any other valid occurrences within the specified bounds). Actual behavior is that an additional unexpected transaction is produced on `2024-06-30`, which violates the start date (`from 2024-07`).

A closely related case also occurs with rules like:

```journal
~ every 16th day of month from 2023-03 to 2024-03
    (asset:cash)        1
```

When requesting a forecast window that is entirely before the start date (for example `hledger print --forecast=2023-02`), nothing should be generated. Actual behavior is that a generated transaction can appear on `2023-02-16` even though the rule’s start date is `2023-03`.

The bug stems from how start dates are interpreted/adjusted for “every Nth day (of month)” style periodic rules and certain report interval computations: the logic sometimes adjusts to a prior matching day (or otherwise expands backwards) and then treats that as a valid first occurrence, even when it is earlier than the explicit `from DATE`.

Fix the date/interval handling so that:

- For periodic rules of the form “every Nth day … from DATE …”, the first generated occurrence is on or after the explicit start date, never before it.
- If the forecast/report range ends before the rule’s start date, no occurrences are produced.
- This corrected behavior also applies consistently to other interval start-date edge cases affected by the same interval/date-adjustment logic (ie, ensure the start date constraint is enforced even when interval alignment or “nearest previous matching day” adjustments are involved).

After the fix, the two examples above must no longer produce `2024-06-30` or `2023-02-16` respectively, while still producing the expected in-range occurrences (eg `2024-07-31`, `2024-08-31`).