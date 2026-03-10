The String module is missing a set of separator-based splitting functions that were discussed for inclusion in the standard library. Implement the following new APIs with consistent behavior across edge cases (especially when the separator is the empty string):

Add these functions:
- String.split_first : sep:string -> string -> (string * string) option
- String.split_last : sep:string -> string -> (string * string) option
- String.split_all : ?drop:bool -> sep:string -> string -> string list
- String.rsplit_all : ?drop:bool -> sep:string -> string -> string list

Semantics:
1) For split_first and split_last:
- They search for the first/last occurrence of sep in the input string s.
- If sep does not occur in s, return None.
- If it occurs, return Some (left, right) where left is the substring before the matched separator and right is the substring after it.
- The matched separator itself is not included in either returned part.

2) For split_all:
- It returns the list of substrings of s separated by occurrences of sep, scanning from left to right.
- It must satisfy the round-trip property for all sep and s:
  String.concat sep (String.split_all ~sep s) = s
- It must handle separators occurring at the start/end of s by producing empty-string elements at the beginning/end of the list (unless removed by the optional drop behavior described below).
- Special case: when sep = "" (empty string), it must follow the same “empty string matches between characters (and at both ends)” behavior used by other empty-substring matching operations. For example:
  String.split_all ~sep:"" "abc" = [""; "a"; "b"; "c"; ""]
  and the round-trip property above must still hold.

3) For rsplit_all:
- It returns the list of substrings split by sep but scanning matches from right to left (rightmost separators first).
- The returned list must still be in left-to-right order of the resulting pieces (i.e., the same list of pieces you’d get from splitting, not reversed pieces), but the way matches are found must correspond to right-to-left matching when there are multiple possible matches.
- It must support sep = "" with behavior consistent with split_all regarding empty-string matches.

4) Optional argument drop (for both split_all and rsplit_all):
- Add an optional boolean argument ?drop.
- When enabled, it drops empty fields that arise from separators at the beginning/end of the string and/or from consecutive separators.
- When drop is not provided (default), do not drop: preserve empty fields so that the round-trip property holds.
- Ensure the behavior is well-defined for sep = "" as well.

The implementation should ensure these functions behave consistently with other String search/match primitives when sep is empty, and should not raise exceptions for ordinary inputs (including empty s or empty sep).