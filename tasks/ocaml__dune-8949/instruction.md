When using Dune with subdirectory module layouts, Menhir and ocamllex stanzas fail to find their source files when the project uses `include_subdirs qualified` (and similarly in setups where parser/lexer sources live in nested directories under a stanza root). For example, a project can have a library/executable declared at a directory root and place `parser.mly` and `lexer.mll` in a subdirectory (e.g. `surface/`). With `include_subdirs` enabled, Dune should be able to associate the Menhir-generated modules and ocamllex-generated modules with the library/executable and locate the `.mly`/`.mll` sources in the correct subdirectory.

Currently, Dune looks for the Menhir and ocamllex input files as if they were located directly in the stanza directory and fails with errors like:

```
Error: No rule found for lib/parser.mly
Error: No rule found for lib/lexer.mll
```

This happens because the Menhir stanza cannot correctly compute/resolve the module’s path within the include_subdirs layout, so it cannot attach itself to the corresponding library/executable module set and derive the correct source location.

Dune should compute the correct module path for Menhir/ocamllex modules under `include_subdirs qualified`, so that builds succeed when the parser/lexer live in nested directories and are referenced as qualified modules from user code (e.g. a generated module being available under its qualified path rather than only as an unqualified module). After the fix, `dune build` for an executable/library using `include_subdirs qualified` and a Menhir parser in a subdirectory should succeed (or at least progress past Menhir/ocamllex rule generation) without “No rule found for …/*.mly” / “No rule found for …/*.mll” errors, and user code should be able to refer to the generated modules via their expected qualified module names.