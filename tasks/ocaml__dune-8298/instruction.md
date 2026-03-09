The shell-action representation for running commands has been refactored so that program arguments are stored as an array (immutable array) rather than a list. After this change, converting actions to shell snippets must continue to preserve argument order and print exactly the same command line formatting as before.

Currently, constructing a run action like:

```ocaml
Action.For_shell.Run ("my_program", Array.Immutable.of_array [| "my"; "-I"; "args" |])
```

should produce a shell command that prints the program name followed by each argument separated by single spaces:

```
my_program my -I args
```

but the new array-based representation causes incorrect formatting in some cases (e.g., missing arguments, wrong order, extra separators, or other regressions in the generated shell string).

Update the action-to-shell conversion so that all existing action constructs still render correctly, including but not limited to:

- `Run (prog, args)` where `args` is an immutable array of strings; all arguments must be emitted in order.
- `Chdir (dir, action)` should still emit `mkdir -p <dir>;cd <dir>;` followed by the nested action’s shell.
- `Setenv (var, value, action)` should still emit `<var>=<value>;` followed by the nested action’s shell.
- `Redirect_out (outputs, path, perm, action)` should still emit the correct redirection operator (`>`, `2>`, `&>`) and, when `perm` is executable, additionally emit `chmod +x <path>` after the command.
- `Ignore (outputs, action)` should still redirect to `/dev/null` using the correct operator.
- `Redirect_in (stdin, path, action)` should still emit input redirection (`< path`) and preserve multi-line bash script quoting/indentation behavior.

The key requirement is that the switch from lists to arrays for arguments must not change externally visible behavior of `Action_to_sh.pp` (and any related action-to-shell rendering functions): the produced shell snippet must be stable and match the expected formatting for each action constructor, especially `Run` argument printing.