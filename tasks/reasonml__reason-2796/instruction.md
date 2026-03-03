Reason syntax currently does not support using reserved keywords (and other normally-illegal identifiers) as user-defined names in bindings, types, modules, classes, externals, labels, record fields, polymorphic variants, etc. This blocks valid programs from being parsed/pretty-printed when users need to interoperate with generated code or external APIs that use keyword-like names.

Add support for “raw identifiers” written with a leading `#` (spelled in source as `\#name`), so that a reserved word can be used as an identifier when prefixed this way. For example, `let \#let = 2;` should parse and format successfully, and references like `\#let` should resolve as the same identifier. Similarly, `and \#and = \#let;` should work.

This must work consistently across:

- Value bindings and references: `let \#let = 2; let \#let = \#let;`
- Labeled arguments and their type annotations/defaults: `(~\#let)` and `(~\#let: \#let=\#let)`
- Type names and type expressions: `type \#type = \#type;`
- Module type identifiers: `module type \#module = \#module;`
- Class and class type identifiers: `class \#class = class \#class;` and `class type \#class = \#class;`
- Polymorphic variants and variant payloads where an identifier-like token appears: `` `\#module `` and `[ \#module ]`
- Externals: `external \#external: unit => unit = "external";`
- Record type fields and record expressions using punning and explicit field assignment, including a mix of raw identifiers and normal identifiers: 
  - `type \#rec = { \#type: \#type, \#module: module_ };`
  - `let \#rec = { \#type: \#type, \#module: module_ }`

The formatter (`refmt`) must preserve the raw-identifier spelling and produce stable output. Formatting should be idempotent: formatting a file containing raw identifiers, then formatting the formatted output again, must produce the same result. 

Also ensure that normal identifiers that happen to match keywords without the raw prefix continue to behave as before. For example, `let true = x => x;` should still be accepted/printed as it currently is, and `let \#true = x => x;` should also be accepted and preserved as a raw identifier.

If raw identifiers are not supported, users currently see parse errors when encountering tokens like `\#let`, or the formatter fails to round-trip them; this should be fixed so these programs parse and format correctly.