Several Mix commands behave poorly when invoked with no positional arguments: they fail with inconsistent messages, and some commands report an unrelated configuration error instead of telling the user they forgot to pass an argument. This makes common “I forgot the argument” mistakes harder to diagnose.

When running the following commands with no arguments, Mix should raise a Mix error that clearly states no argument was given and includes guidance to either use the correct invocation form or run the corresponding help command. Currently, the behavior is inconsistent (some commands say “expected at least one argument”, some say “xref doesn’t support this command”, and some escript-related commands can surface an unrelated “please set :main_module” error).

Update the relevant Mix tasks so that calling them with an empty argv produces improved, consistent errors:

- `mix archive.uninstall` with no args should fail with:
  `** (Mix) No argument was given to uninstall command.  Use "mix archive.uninstall PATH" or run "mix help archive.uninstall" for more information`

- `mix cmd` with no args should fail with:
  `** (Mix) No argument was given to mix cmd. Run "mix help cmd" for more information`

- `mix escript.build` with no args should fail with the existing escript error message plus the help hint appended:
  `** (Mix) Could not generate escript, please set :main_module in your project configuration (under :escript option) to a module that implements main/1. Run "mix help escript.build" for more information`

- `mix escript.install` with no args should fail with the same message as `mix escript.build` above (including the `mix help escript.build` hint).

- `mix escript.uninstall` with no args should fail with:
  `** (Mix) No argument was given to uninstall command.  Use "mix archive.uninstall PATH" or run "mix help archive.uninstall" for more information`

- `mix eval` with no args should fail with the existing message plus the help hint appended:
  `** (Mix) "mix eval" expects a single string to evaluate as argument. Run "mix help eval" for more information`

- `mix new` with no args should fail with:
  `** (Mix) Expected PATH to be given. Use "mix new PATH" or run "mix help new" for more information`

- `mix xref` with no args should fail with:
  `** (Mix) No argument was given to xref command. Run "mix help xref" for more information`

In all cases, the command should raise `Mix.Error` (or the equivalent Mix failure mechanism) with exactly the improved messaging and without falling through to unrelated errors or generic “unsupported command” messages when the real issue is simply missing arguments.