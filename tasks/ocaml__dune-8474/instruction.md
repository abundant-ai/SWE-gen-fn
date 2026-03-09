`dune exec` does not correctly support pform syntax (e.g. `%{bin:<public_name>}`) when it appears in the command to execute and/or in arbitrary argument positions. The command should accept pforms in the executable position and in any later argument, expanding them before execution, and ensuring any referenced binaries are built/available.

When a user runs a command like:

- `dune exec %{bin:e} a b c`

`dune exec` should expand `%{bin:e}` to the installed build path of the binary `e` (for example a path under `_build/install/.../bin/e`), then execute it with the remaining arguments, so that the executed program sees `argv[0]` as the expanded path and `argv[1..]` as the provided arguments.

Pforms must also be supported when they appear in argument positions rather than as the first item to execute. For example, if a wrapper script is executed and one of its arguments is `%{bin:e}`, that argument must be expanded before the wrapper is executed, so the wrapper receives the expanded path and can run it.

Additionally, if the first item is a normal program name (not a pform), it should continue to be resolved via `PATH` as before, while any later pform arguments are still expanded. For example:

- `dune exec ls %{bin:e}`

should run `ls` from `PATH` and list the expanded path for `%{bin:e}`.

Multiple pforms can appear in the same invocation and must each be expanded independently (e.g. `dune exec ls %{bin:e} %{bin:e}` should result in two expanded paths).

Finally, pform-referenced binaries should be treated as build targets so that `dune exec` ensures they are built before running. This includes cases where the executed program itself is a pform-expanded binary and it is given another pform-expanded binary as an argument. For example, executing a binary via `%{bin:call_arg}` and passing `%{bin:called}` as its first argument should succeed even when neither has been built yet: both binaries must be compiled, `%{bin:...}` expansions must point to the correct built/installed paths, and the outer program must be able to execute the inner one successfully.

In summary: implement/repair pform expansion support in `dune exec` so that `%{bin:...}` works in the program position and any argument position, preserves `PATH` lookup for non-pform executables, supports multiple occurrences, and triggers building of any referenced binaries prior to execution.