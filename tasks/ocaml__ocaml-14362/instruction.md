OCaml’s standard String module is missing a convenient set of functions for taking/dropping characters while a predicate holds at the beginning or end of a string, and for cutting a string into two parts at the first/last position where a predicate stops holding. Implement the following new functions in module String, with the semantics described below:

Implement `String.take_first_while : (char -> bool) -> string -> string` and `String.drop_first_while : (char -> bool) -> string -> string`.
- `take_first_while p s` returns the longest prefix of `s` consisting only of characters `c` such that `p c` is true.
- `drop_first_while p s` returns `s` with that longest prefix removed.
- For all `p` and `s`, `String.take_first_while p s ^ String.drop_first_while p s = s`.
- If the predicate holds for no initial characters, `take_first_while` returns `""` and `drop_first_while` returns `s`.
- If the predicate holds for all characters, `take_first_while` returns `s` and `drop_first_while` returns `""`.

Implement `String.take_last_while : (char -> bool) -> string -> string` and `String.drop_last_while : (char -> bool) -> string -> string`.
- `take_last_while p s` returns the longest suffix of `s` consisting only of characters satisfying `p`.
- `drop_last_while p s` returns `s` with that longest suffix removed.
- For all `p` and `s`, `String.drop_last_while p s ^ String.take_last_while p s = s`.
- Edge cases mirror the “first” variants (empty string, predicate never holds, predicate always holds).

Implement `String.cut_first_while : (char -> bool) -> string -> string * string` and `String.cut_last_while : (char -> bool) -> string -> string * string`.
- `cut_first_while p s` returns a pair `(a, b)` where `a` is `take_first_while p s` and `b` is `drop_first_while p s`.
- `cut_last_while p s` returns a pair `(a, b)` where `a` is `drop_last_while p s` and `b` is `take_last_while p s`.
- These should be consistent with the take/drop functions, including the concatenation identities above.

These functions must work correctly for empty strings and for all character values; they must not raise exceptions for any input string. Ensure they behave correctly when the cut point is at index 0 or at the end of the string.

After implementing, the new functions should be part of the public String API so user code can call them as `String.take_first_while ...`, etc., and they should interoperate predictably with other String operations like concatenation and substringing.