When importing CSV using a rules file, regex capture group references (eg \\1, \\2) are incorrectly scoped when more than one `if` block matches the same record. If two different `if` conditionals both match a single CSV record and at least one of them uses capture groups, later field assignments may interpolate the wrong capture groups (from a different match), producing mixed-up output.

Example rules scenario:

- A record with description `SUFFIX Text 1 - Text 2` matches both:
  - `if %desc SUFFIX (.*)`
  - `if %desc SUFFIX (.*) - (.*)`

Expected behavior: each `if` block’s capture groups should be local to that block’s match, so an assignment like `account1 account:\1:\2` inside the second block should interpolate to `account:Text 1:Text 2`.

Actual behavior: capture groups from the first match leak or get conflated with the second match’s groups, producing something like `account:Text 1 - Text 2:Text 1` (ie the “\\1” resolves to the entire `Text 1 - Text 2` from the first regex, while “\\2” resolves to `Text 1` from the second regex).

This also affects non-field matchers/record matchers (eg matching literal text like `(Zettle)` followed by a different regex with nested parentheses) where a later block’s interpolation tokens resolve as if group numbering had been offset by prior matches, rather than starting at \\1 for each independent match.

Fix the rules/CSV import matching so that, for each conditional block that matches (whether it’s a field matcher like `%date (....-..)-..`, a field matcher with parentheses like `%account1 liabilities:jon:(.*)`, or a record matcher like `Zettle.*(Robert W. (Bell)).*£`), the capture group environment used for interpolating backreferences in that block’s assignments is derived only from that block’s own regex match, with group numbering starting at \\1 for that match. Multiple matching `if` blocks applied to the same record must not affect each other’s capture group numbering or values.

After the fix, evaluating the rules should yield `Just "account:Text 1:Text 2"` for the relevant assigned field in the overlapping-match case, not `Just "account:Text 1 - Text 2:Text 1"`.