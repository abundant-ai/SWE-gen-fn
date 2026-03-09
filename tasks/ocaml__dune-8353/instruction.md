Dune currently treats macros (pforms) as if they only accept a single string argument, and several macros simulate multiple arguments by packing them into one string separated by ":" (for example, `%{lib:public_lib:a.ml}` where the library name and file are effectively multiple arguments). Because multi-argument handling is not part of the core macro representation, the logic for splitting on ":" is duplicated in multiple, unrelated parts of the codebase. This causes inconsistencies and makes it easy for macro expansion to interpret arguments differently depending on which macro is being expanded.

Update the macro representation so that macros can natively carry multiple arguments in `Pform.t`, and centralize parsing of colon-delimited arguments so every macro sees the same argument structure.

After the change, pforms like `%{lib:public_lib:a.ml}` and `%{lib-private:private_lib:a.ml}` must be parsed as a macro name plus an ordered list of arguments (e.g., `"public_lib"`, `"a.ml"`) rather than as a single raw string that each expander manually splits.

The following behaviors must work end-to-end when these macros are used inside actions such as `(echo "...")`:

- `%{lib:<public-library>:<path>}` expands to the installation path of `<path>` within the named public library. For example, with a public library `public_lib` that installs `a.ml`, expanding `%{lib:public_lib:a.ml}` should produce a path like `../install/default/lib/public_lib/a.ml`.

- Using `%{lib:<private-name>:<path>}` where the library is not public must fail with an error explaining that the library is not public and that `lib` expands to an installation path which is not defined for private libraries. The error should be reported at the location of the macro occurrence.

- `%{lib-private:<lib>:<path>}` must be rejected when the project is using a Dune language version older than 2.1, with an error stating that `%{lib-private:..}` is only available since version 2.1 and instructing to update `(lang dune 2.1)`.

- When the Dune language version is at least 2.1, `%{lib-private:<lib>:<path>}` must work for both public and private libraries, expanding to the source path corresponding to `<path>` in that library (e.g., `src/a.ml` for a library defined in `src`).

Ensure the argument parsing is performed once during pform parsing into `Pform.t` (or equivalent pform AST), and macro expanders consume structured arguments rather than re-splitting strings. Errors for wrong arity or invalid forms should be consistent across macros and should not depend on which expander happens to be invoked.