The OCaml standard library’s String module is missing the string-searching primitives that have been discussed for inclusion: forward and reverse substring search returning either indices or substrings, plus functions that return all occurrences.

Implement the following new functions in String with the specified behavior:

1) `String.find_first_index` and `String.find_last_index`

These search for a single character in a string and return the index of the first/last occurrence.

- Signature shape:
  - `String.find_first_index : ?start:int -> (char -> bool) -> string -> int option`
  - `String.find_last_index  : ?start:int -> (char -> bool) -> string -> int option`
- Semantics:
  - They scan the string starting from `start` and moving forward (`find_first_index`) or backward (`find_last_index`).
  - The predicate argument is applied to each character; the first/last index whose character satisfies the predicate is returned.
  - If there is no matching character, return `None`.
- `start` handling:
  - Default `start` is `0` for `find_first_index` and `String.length s - 1` for `find_last_index`.
  - If `start` is out of range for the string (e.g. negative; or greater than the last valid index when searching), raise `Invalid_argument` with the same error message style used by other String functions taking `~start`.

2) `String.find_first` and `String.find_last`

These perform substring search and return the matching substring (the “needle”) when found.

- Signature shape:
  - `String.find_first : ?start:int -> string -> string -> string option`
  - `String.find_last  : ?start:int -> string -> string -> string option`
- Semantics:
  - The second argument is the needle to find inside the haystack (third argument).
  - `find_first` returns `Some needle` if the needle occurs at or after `start`, otherwise `None`.
  - `find_last` returns `Some needle` if the needle occurs at or before `start` when searching backwards, otherwise `None`.
  - Returning the needle (not the surrounding text) is intentional; the primary purpose is existence checking in combination with index-search variants.
- Edge cases:
  - Empty needle: treat as found at the boundary implied by the search direction and start.
    - For forward search: an empty needle is found at `start` (or at `0` if start defaults).
    - For reverse search: an empty needle is found at `start` (or at `String.length haystack`/`String.length haystack - 1` depending on the consistent boundary you choose), but it must behave consistently with the corresponding index-returning variant.
  - If the needle is longer than the haystack region being searched, return `None`.
- `start` handling:
  - Must validate `start` similarly to other String functions: out-of-range starts raise `Invalid_argument` with the standard message.

3) `String.find_all` and `String.rfind_all`

These return all (non-overlapping) occurrences of a needle within a haystack, in search order.

- Signature shape:
  - `String.find_all  : ?start:int -> string -> string -> int list` (or an equivalent occurrence representation used consistently by replace/split APIs)
  - `String.rfind_all : ?start:int -> string -> string -> int list`
- Semantics:
  - `find_all` returns occurrences from left to right starting at `start`.
  - `rfind_all` returns occurrences from right to left starting from `start`.
  - Occurrences must be non-overlapping (e.g. searching for "aa" in "aaaa" should yield indices `[0;2]` for forward search).
  - `start` validation and empty-needle handling must be well-defined and consistent with `find_first`/`find_last`.

General requirements:
- All of these functions must handle boundary conditions correctly: empty strings, empty needle, start at extremes, and start outside the valid range.
- Reverse-search variants must be semantically equivalent to doing the same search from the end: they should find the last possible match at or before the start point, not simply reverse the list of forward matches.
- Error behavior must be consistent with existing String functions: invalid `start` arguments must raise `Invalid_argument` (not return `None`).

Example expectations (illustrative):
- `String.find_first_index (fun c -> c = 'x') "abc" = None`
- `String.find_first_index ~start:1 (fun c -> c = 'b') "abc" = Some 1`
- `String.find_last_index (fun c -> c <> ' ') " abc " = Some 4`
- `String.find_first ~start:0 "bar" "foobarbaz" = Some "bar"`
- `String.find_last  ~start:8 "bar" "foobarbaz" = Some "bar"`
- `String.find_all "ana" "bananas"` returns indices corresponding to non-overlapping matches in forward order.

Implement these APIs so they are available from `String` and behave consistently across forward and reverse searches, including correct exception behavior for invalid starts.