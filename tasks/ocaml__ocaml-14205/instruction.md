When the compiler is invoked on an implementation provided as a marshalled AST (e.g., a PPX-expanded artifact such as `foo.pp.ml` passed via `-impl`), inclusion-check error messages can incorrectly report the implementation and interface filenames as the marshalled artifact name rather than the original source file.

Reproduction scenario: parse an implementation source file `foo.ml` into an AST and write it out to a file named `foo.pp.ml` (as a marshalled AST). Then compile an interface `foo.mli` that is incompatible with the implementation, and finally invoke the compiler on `-impl foo.pp.ml` while pointing it at the compiled interface (e.g., using `-cmi-file foo.cmi`). Even if the original `foo.ml` file is no longer present on disk (for example, due to sandboxing), the compiler should still report errors in terms of the original source filename recorded in the AST.

Actual behavior: the inclusion-check error references a fictitious implementation file named `foo.pp.ml` (and may also mention it as the interface in the header line), leading to confusing diagnostics such as:

`Error: The implementation foo.pp.ml does not match the interface foo.pp.ml:`

Expected behavior: the same error should instead reference the original source names:

- The header should say the implementation is `foo.ml` and the interface is `foo.mli`.
- The “Actual declaration” location should be reported as coming from `foo.ml` (with correct line/character ranges), not from `foo.pp.ml`.

For example, given `foo.ml` containing `let foo = 0` and `foo.mli` declaring `val foo : unit`, the diagnostic should be of the form:

`File "foo.ml", line 1:`
`Error: The implementation foo.ml does not match the interface foo.mli:`
`       Values do not match: val foo : int is not included in val foo : unit`
`       ...`
`       File "foo.mli", line 1, characters 0-14: Expected declaration`
`       File "foo.ml", line 1, characters 4-7: Actual declaration`

Implement the fix so that the compiler keeps track of (1) the file name explicitly passed to the compiler (`foo.pp.ml`) and (2) the original source file name stored inside the unmarshalled AST (`foo.ml`), and uses the original source name for user-facing locations and inclusion-check error messages.