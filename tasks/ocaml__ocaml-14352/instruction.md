Several convenience string-splitting helpers are missing from the standard library. Add the following new functions to the `String` module: `String.take_first`, `String.drop_first`, `String.cut_first`, `String.take_last`, `String.drop_last`, and `String.cut_last`.

These functions are meant to “split strings with magnitudes”: they operate on a string and an integer count, and return either a prefix/suffix of that size, the remainder after removing that prefix/suffix, or both parts at once.

Implement the APIs with the following required behavior:

- `String.take_first n s` returns the first `n` characters of `s`.
  - If `n <= 0`, it returns the empty string.
  - If `n >= String.length s`, it returns `s` unchanged.

- `String.drop_first n s` returns `s` with the first `n` characters removed.
  - If `n <= 0`, it returns `s` unchanged.
  - If `n >= String.length s`, it returns the empty string.

- `String.cut_first n s` returns a pair `(prefix, rest)` where `prefix` is the result of `String.take_first n s` and `rest` is the result of `String.drop_first n s`. The two parts must concatenate back to the original string (`prefix ^ rest = s`) for all integer values of `n`.

- `String.take_last n s` returns the last `n` characters of `s`.
  - If `n <= 0`, it returns the empty string.
  - If `n >= String.length s`, it returns `s` unchanged.

- `String.drop_last n s` returns `s` with the last `n` characters removed.
  - If `n <= 0`, it returns `s` unchanged.
  - If `n >= String.length s`, it returns the empty string.

- `String.cut_last n s` returns a pair `(rest, suffix)` where `suffix` is the result of `String.take_last n s` and `rest` is the result of `String.drop_last n s`. The two parts must concatenate back to the original string (`rest ^ suffix = s`) for all integer values of `n`.

These functions must be total (no exceptions) for all integer `n` values, including negative values and values larger than the string length, and must behave consistently with the clamping rules above.