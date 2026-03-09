In Dune action/variable expansion, the `%{bin:...}` and `%{bin-available:...}` forms currently fail when given a relative path containing a slash, such as `%{bin:./x}` or `%{bin-available:./x}`. These forms effectively never succeed, even when `./x` refers to a runnable program available relative to the current build directory or to a locally provided binary (e.g., via `binaries`/environment configuration).

The expected behavior is that relative paths in these forms are interpreted as paths relative to the current directory of the rule/action being executed, rather than being treated as bare program names to be searched only via PATH or installed/public binaries.

When expanding `%{bin-available:./prog}` it should return:
- `true` if `./prog` resolves to an executable file relative to the action’s working directory, or if it resolves to a locally provided binary at that relative path (for example via an environment `binaries` mapping that makes `./foo` available in that directory).
- `false` if the relative path resolves to a non-existent file, a directory, or a binary that is disabled (e.g., excluded via `enabled_if false`).

When expanding `%{bin:./prog}` it should resolve the executable the same way (relative to the current directory) and allow `(run %{bin:./prog})` to execute it successfully when available. If the relative path cannot be resolved to an executable, `%{bin:...}` should fail with Dune’s usual “program not found” style error for `%{bin:...}` expansions.

Concrete scenarios that must work:
- If there is an executable `e` built/provided in the current directory, `%{bin-available:./e}` evaluates to `true` and `(run %{bin:./e})` runs it.
- If there is an executable file `pathonly` located at `./pathonly` relative to the current directory, `%{bin-available:./pathonly}` is `true` and `(run %{bin:./pathonly})` runs it.
- If `./dironly` exists but is a directory, `%{bin-available:./dironly}` is `false`.
- If `./foo` does not exist in the current directory, `%{bin-available:./foo}` is `false`.
- If a binary is declared but disabled via `enabled_if false`, then `%{bin-available:./disabled}` is `false`.
- In a nested subdirectory rule, `%{bin-available:./foo}` should be evaluated relative to that subdirectory (not the repository root), and should correctly reflect binaries made available in that nested context.

The main bug to fix is that `%{bin:...}` and `%{bin-available:...}` treat relative paths containing slashes as unresolvable program names; they must instead recognize relative paths and resolve them from the current directory context used for the action.