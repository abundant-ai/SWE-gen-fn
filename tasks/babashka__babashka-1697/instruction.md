Babashka’s handling of `--` (end-of-options delimiter) is inconsistent across execution modes, and REPL sessions don’t reliably expose the provided command-line arguments via `*command-line-args*`.

Currently, argument separation behaves incorrectly in several scenarios:

1) When starting a REPL via the `repl` subcommand or `--repl`, arguments after `--` may still be interpreted as babashka options / file names. For example:

```bash
bb repl -- asdf sdf <<< '*command-line-args*'
```

This should start a REPL and treat `asdf sdf` as user arguments (available via `*command-line-args*`), but instead babashka tries to treat `asdf` as a file and errors:

```
java.lang.Exception: File does not exist: asdf
```

The `repl` / `--repl` mode must consume only the REPL flag/subcommand itself from the argument list and then respect `--` as the boundary after which arguments are not parsed as babashka options.

2) When starting a REPL without explicitly using `repl` / `--repl` (i.e., invoking babashka such that it enters REPL mode through the default path), `*command-line-args*` is currently `nil` even if arguments were provided after `--`. For example:

```bash
bb -- asdf sdf <<< '*command-line-args*'
```

This should evaluate in the REPL to a sequence containing the provided arguments:

```clojure
("asdf" "sdf")
```

but it currently evaluates to `nil`.

Fix the REPL entry paths so that `*command-line-args*` is correctly bound to the arguments that appear after `--` (or to an empty/nil value when no such arguments are provided, consistent with existing babashka semantics), and ensure the `--` delimiter stops babashka option/file processing in REPL mode as it does in script/file mode.

Relevant functions involved in parsing include `babashka.main/parse-global-opts` and `babashka.main/parse-opts`; REPL startup paths in `babashka.main` must propagate/bind the parsed `:command-line-args` so that REPL evaluation of `*command-line-args*` reflects the CLI arguments supplied by the user.