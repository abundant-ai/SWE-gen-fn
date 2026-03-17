A regression in babashka v1.3.187 causes certain script arguments to be misinterpreted as babashka’s own CLI commands/options when they overlap with built-in bb subcommands. In particular, running a script and passing the literal string "version" as the first script argument incorrectly triggers babashka’s version-printing behavior instead of executing the script with that argument.

Reproduction:

Create a script like:

```clojure
#!/usr/bin/env bb

(defn run
  [[command :as input]]
  (if (= "version" command)
    (println "do something")
    (println "otherwise")))

(run *command-line-args*)
```

Run it with:

```bash
./my-script version
```

Actual behavior:

It prints the babashka version, e.g.:

```
babashka v1.3.187
```

Expected behavior:

The script should execute normally and `*command-line-args*` should include the provided argument, so the output should be:

```
do something
```

The CLI parsing logic should distinguish between:

- babashka being invoked to run a script/file (or other non-subcommand mode), where subsequent tokens are script arguments and must not be reinterpreted as bb subcommands (like `version`), and
- babashka being invoked in “bb subcommand” mode (e.g. `bb version`, `bb run`, `bb tasks`, etc.), where those tokens are intended to be handled by babashka.

Implement the fix in the argument parsing functions used by the entrypoint, ensuring `main/parse-global-opts` and `main/parse-opts` correctly preserve script arguments even when they match bb subcommand names. `--` must continue to explicitly terminate option parsing so that arguments after it (including ones that look like options such as `-e`) are always passed through as `:command-line-args` unchanged.

After the fix, invoking babashka to run code (via a script file or similar) must not treat "version" (and other overlapping bb subcommand tokens) as a request to print version; it must pass them through as normal command-line args to the user program.