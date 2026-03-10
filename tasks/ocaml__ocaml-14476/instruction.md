When compiling some projects with occurrence indexing enabled (e.g., using compiler flags like `-bin-annot -bin-annot-occurrences`), the compiler can crash with an assertion failure:

`Fatal error: exception File "typing/env.ml", line 1155, characters 9-15: Assertion failed`

This has been observed while building real-world packages (e.g., menhirLib and csexp) on OCaml trunk when occurrence indexing is produced.

The crash happens during UID resolution for occurrences: `Env.find_uid` attempts to resolve UIDs for constructors and record labels using “shape-only” paths that encode constructors/fields via an extended path form (using `Pextra_ty _`). Those extended paths are valid inside shapes but are not valid for regular typing environment lookups. When `Env.find_uid` tries to resolve these paths by performing a normal type lookup (e.g., via `find_type`), the lookup can reach code that assumes only standard paths and triggers an internal `assert false` (notably when computing the type of a constructor).

`Env.find_uid` needs to be refined so that it correctly resolves UIDs for these shape-encoded references without passing invalid extended paths into the standard environment queries. In particular, UID lookup must specifically handle extended paths used to represent:

- extension constructors
- regular variant constructors
- record labels

Expected behavior: compiling code with `-bin-annot-occurrences` should never crash the compiler. When code refers to constructors, extension constructors, or record fields via functor/module paths (including cases like `X.A`, `X.B { r = () }`, `{ X.x = () }`, and `X.E` where `E` is an extension constructor), occurrence indexing should successfully produce stable UIDs for those references.

Actual behavior: in these scenarios, UID resolution can trigger an assertion failure due to invalid path handling, aborting compilation.

After the fix, occurrence indexing should complete successfully and UID dependency/index output should include resolvable UIDs for constructor and label occurrences in functorized/module-parameter code (including nested module paths and record/constructor selections).