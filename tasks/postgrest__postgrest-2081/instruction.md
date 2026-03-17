The `is` filter operator should accept NULL and trilean values case-insensitively, but currently fails to parse uppercase or mixed-case values.

Reproduction:
A request like:

GET /projects?id=is.NULL

currently fails with an error similar to:

{"details":"unexpected \"N\" expecting null or trilean value (unknown, true, false)","message":"\"failed to parse filter (is.NULL)\" ..."}

Expected behavior:
- `is` should treat its right-hand operand in a case-insensitive way for the special values it supports.
- The following should be accepted and behave the same as their lowercase forms:
  - `is.null`, `is.NULL`, `is.Null`, etc.
  - Trilean values: `is.true`, `is.false`, `is.unknown` should also work with `TRUE/FALSE/UNKNOWN` and any mixed casing.
- `not.is.<value>` should likewise support these values case-insensitively.

Actual behavior:
- Only lowercase values (e.g., `is.null`) are accepted.
- Uppercase or mixed-case values (e.g., `is.NULL`) cause filter parsing to fail and return a 4xx error.

Fix the filter parsing/handling so that `is` (and `not.is`) correctly recognizes these special operands regardless of case, without changing the semantics for other operators or non-special literal values.