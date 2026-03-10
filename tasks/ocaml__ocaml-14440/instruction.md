OCaml’s standard library currently lacks a direct way to create a one-character string from a `char`, leading to widespread use of the more awkward idiom `String.make 1 c`. This is especially noticeable in code that joins or re-concatenates strings using a separator character, where callers end up writing `String.make 1 sep` to get the separator as a string.

Add a new function `String.of_char : char -> string` to the `String` module.

Expected behavior:
- `String.of_char c` returns a string of length 1 whose only character is `c`.
- For any character `c`, `String.length (String.of_char c) = 1` and `String.get (String.of_char c) 0 = c`.
- `String.of_char c` should be equivalent in result to `String.make 1 c`.

The new API must be exposed as part of the public `String` module interface so it can be used by callers (including in expressions like `String.concat (String.of_char sep) parts`).