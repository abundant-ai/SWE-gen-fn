There is a regression in Reason’s formatter (refmt) around printing extension nodes when “quoted extensions” support is involved. When formatting code that uses extension sugar (e.g. `let%extend`, `if%extend`, `switch%extend`, `try%extend`, and structure-level `[%extend ...]`), refmt must preserve the original extension name formatting for non-quoted extensions.

Currently, when the code contains extensions whose names are not quoted (plain identifiers like `extend`, `extend1`, `extend2`), refmt incorrectly prints them as if they were quoted extensions, or otherwise changes how the extension name is rendered. This breaks round-tripping/format stability for common extension forms such as:

```reason
[%extend open M];
let%extend x = "hi";
if%extend (true) {1} else {2};
switch%extend (None) { | Some(x) => ... | None => () };
try%extend(raise(Not_found)) { | Not_found => () };
```

The problem also shows up when extensions are nested or sequenced, for example having an outer structure extension wrapping an inner expression/statement extension (e.g. `[%extend1 ... try%extend2() ...]`), and in cases where extension-sugar appears within blocks, within top-level bindings, and as standalone structure items.

Expected behavior: formatting should keep non-quoted extension names printed in their non-quoted form exactly as valid extension sugar expects (e.g. `let%extend`, `if%extend`, `try%extend`, `[%extend ...]`, and similarly for `extend1`/`extend2`), without adding quotes or otherwise altering the extension name representation.

Actual behavior: after formatting, non-quoted extensions are printed using the wrong quoting/printing mode (treated like quoted extensions), causing the output to differ from the intended stable printed form.

Fix refmt’s extension printing logic so that quoted-extension handling does not affect non-quoted extensions, across all extension positions supported by Reason syntax (structure items, expressions, patterns/function cases, and nested/stacked extensions).