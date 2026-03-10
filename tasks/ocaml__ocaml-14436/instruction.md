The OCaml standard library’s String module is missing convenient substring replacement operations discussed publicly: the ability to replace only the first match, only the last match, or all matches of a given pattern within a string.

Implement three new functions in the String module:

- String.replace_first
- String.replace_last
- String.replace_all

They should perform substring replacement on a source string, producing a new string where occurrences of a given “pattern” (the substring to search for) are replaced by a given “replacement” string.

The functions must behave consistently with the existing String searching primitives (the same notion of what counts as an occurrence, including handling of overlapping occurrences in the same way as the underlying search functions).

Required behavior:

1) Basic replacement

- Replacing the first occurrence updates only the earliest match.
- Replacing the last occurrence updates only the latest match.
- Replacing all occurrences updates every match in the string.

Example expectations:

- String.replace_first ~sub:"ana" ~by:"X" "bananas" returns "bXnas"
- String.replace_last  ~sub:"ana" ~by:"X" "bananas" returns "banXs"
- String.replace_all   ~sub:"na"  ~by:"X" "bananas" returns "baXXas"

2) No match

If the substring does not occur in the input, the result must be exactly the original string (not raising exceptions).

- String.replace_first ~sub:"zz" ~by:"X" "abc" returns "abc"
- Same for replace_last and replace_all.

3) Empty pattern

Define and implement behavior for an empty substring pattern. This must be handled explicitly (it must not loop forever or allocate unboundedly).

- String.replace_first ~sub:"" ~by:"X" "abc" should insert the replacement at the beginning: "Xabc".
- String.replace_last  ~sub:"" ~by:"X" "abc" should insert the replacement at the end: "abcX".
- String.replace_all   ~sub:"" ~by:"X" "abc" should insert the replacement between every character and also at both ends, producing "XaXbXcX".
- For the empty input string "", replace_first and replace_last should both produce the replacement once ("X"), and replace_all should also produce "X".

4) Correctness with repeated/adjacent occurrences

Ensure adjacent matches are handled properly.

- String.replace_all ~sub:"aa" ~by:"b" "aaaa" should replace two matches, producing "bb".

5) API shape

Expose these functions as part of the public String module API using labeled arguments for the pattern and replacement (e.g. ~sub and ~by), consistent across all three functions.

If any of these functions are invoked with inputs that could cause invalid internal indexing, they must still behave as described above (returning the correct transformed string) rather than raising exceptions.