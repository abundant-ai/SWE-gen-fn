Reason syntax currently can’t express OCaml-style “refutation cases” in pattern matching (as described in the OCaml manual section on refutation cases and redundancy). Users want to be able to write a switch/match branch that explicitly states a case is impossible and should be rejected by the type system if it is actually reachable.

Add support for a refutation clause in Reason pattern matching so that code like the following is accepted and formatted correctly:

```reason
switch (x) {
| A => /* handle */
| B => /* handle */
| _ => .
};
```

The key behavior is that the right-hand side `.` is a special refutation expression for a match/switch branch, not a normal expression. It should be parsed as part of the switch/match syntax, preserved in the AST, and printed back by the formatter as `| pattern => .` (with the usual formatting rules for switch branches).

Expected behavior:
- `switch`/`match` branches may use `=> .` to denote a refutation case.
- The formatter should round-trip this syntax without rewriting it into something else or failing.
- The syntax should work with common patterns such as `_` as well as other patterns that might be marked impossible by the type system.

Current behavior:
- Using `.` as the branch body is not recognized as valid syntax for a switch/match branch and results in a parse/format failure (or the code cannot be represented/printed correctly).

Implement the end-to-end support needed for this feature: parsing, AST representation, and printing/formatting so that refutation cases are accepted and stable under formatting.