OCaml’s standard String module has `String.starts_with ~prefix` and `String.ends_with ~suffix`, but there is no equivalent API to check whether a string contains a given substring. Add a new function `String.includes : affix:string -> string -> bool` that returns whether the second argument contains `affix` as a contiguous substring.

Calling `String.includes ~affix s` should behave like a substring search predicate:

- `String.includes ~affix:"" s` must return `true` for any `s`, including `""`.
- `String.includes ~affix` must return `false` when `affix` is longer than the searched string.
- It must return `true` when `affix` occurs at the beginning, in the middle, or at the end of the searched string.
- It must return `false` when no occurrence exists.

Examples that must work:

```ocaml
assert (String.includes ~affix:"oob" "foobarbaz")
assert (String.includes ~affix:"" "foobarbaz")
assert (String.includes ~affix:"" "")
assert (not (String.includes ~affix:"foobar" "bar"))
assert (not (String.includes ~affix:"foo" ""))
```

The function should be part of the public `String` API and usable like other String predicates (similar calling convention to `starts_with`/`ends_with`).