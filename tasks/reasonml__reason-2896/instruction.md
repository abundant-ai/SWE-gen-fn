When building or consuming the Reason toolchain as a library, several modules under the `Reason_toolchain` namespace are missing interface (`.mli`) definitions. This causes downstream consumers (and internal components compiled with stronger interface checking) to either fail to compile or to rely on unintended/unstable implementation details.

In particular, code that drives the toolchain end-to-end needs to be able to:

- Create a lexer buffer from stdin using `Reason_toolchain.setup_lexbuf ~use_stdin:true filename`.
- Parse an implementation using `Reason_toolchain.RE.implementation` (returning a structure AST).
- Convert parsed AST values between “current compiler AST” and the toolchain’s representation using `Reason_toolchain.To_current.copy_structure`.
- Convert printed/signature-related values back to the toolchain representation using `Reason_toolchain.From_current.copy_out_sig_item`.

Currently, these functions/modules are not consistently exposed via stable interfaces, leading to compilation failures like “Unbound value Reason_toolchain.setup_lexbuf” or signature mismatches where a consumer cannot typecheck calls such as `Reason_toolchain.RE.implementation` or cannot access `Reason_toolchain.To_current.copy_structure` / `Reason_toolchain.From_current.copy_out_sig_item`.

The toolchain should provide explicit `.mli` interfaces that publicly expose the needed modules and function signatures so that an external program can parse/typecheck input and print an outcometree signature phrase by combining:

- `Reason_toolchain.setup_lexbuf`
- `Reason_toolchain.RE.implementation`
- `Reason_toolchain.To_current.copy_structure`
- `Reason_toolchain.From_current.copy_out_sig_item`

After adding the interfaces, a consumer should be able to compile code that:

1) reads an implementation from stdin, 2) parses it with `Reason_toolchain.RE.implementation`, 3) copies the resulting structure into the current compiler AST via `Reason_toolchain.To_current.copy_structure`, and 4) maps over signature items converting them with `Reason_toolchain.From_current.copy_out_sig_item` before printing.

No behavior change is required beyond making the intended API available and correctly typed; the main requirement is that these identifiers resolve and typecheck for external callers across supported OCaml versions.