The OCaml standard library is missing a convenience predicate to check whether a string is empty. Add a new function `String.is_empty : string -> bool` analogous to `List.is_empty`.

When calling `String.is_empty s`, it should return `true` if and only if `String.length s = 0`, and `false` otherwise. In particular:
- `String.is_empty ""` must be `true`.
- `String.is_empty "a"` must be `false`.
- `String.is_empty " abc def "` must be `false`.

The new function must be exposed as part of the `String` module’s public API so it can be used by downstream code. It should behave correctly for all valid strings and should not raise exceptions.

After adding this API, ensure the library and compiler build succeed and that the standard library string tests that exercise string helpers (including interaction with other `String` operations such as `String.drop`) pass when using `String.is_empty` to detect the empty-string case.