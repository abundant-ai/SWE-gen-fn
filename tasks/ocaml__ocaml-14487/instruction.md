The OCaml standard library’s String module is missing convenience functions for removing a known prefix or suffix from a string.

Implement two new functions:

- `String.drop_prefix : prefix:string -> string -> string option`
- `String.drop_suffix : suffix:string -> string -> string option`

Behavior:

- `String.drop_prefix ~prefix s` should return `Some rest` when `s` starts with `prefix`, where `rest` is `s` with exactly that leading `prefix` removed. If `s` does not start with `prefix`, return `None`.
- `String.drop_suffix ~suffix s` should return `Some rest` when `s` ends with `suffix`, where `rest` is `s` with exactly that trailing `suffix` removed. If `s` does not end with `suffix`, return `None`.

Edge cases that must work:

- Empty prefix/suffix: dropping an empty prefix or suffix should always succeed and return `Some s` unchanged (including when `s` is empty).
- Prefix/suffix longer than the input string: should return `None`.
- Exact match: if `s` equals `prefix` (or `suffix`), the result should be `Some ""`.
- Must behave consistently with `String.starts_with` and `String.ends_with` for determining whether the drop succeeds.

The new functions must be part of the public `String` API (available to users without opening internal modules) and should not change the behavior of existing `String.starts_with`/`String.ends_with` functions.

Example expected outcomes:

```ocaml
String.drop_prefix ~prefix:"> " "> quoted" = Some "quoted"
String.drop_prefix ~prefix:"/" "path/to" = Some "path/to"
String.drop_prefix ~prefix:"foo" "bar" = None

String.drop_suffix ~suffix:"/index.html" "/docs/index.html" = Some "/docs"
String.drop_suffix ~suffix:"" "abc" = Some "abc"
String.drop_suffix ~suffix:"baz" "foobar" = None
```