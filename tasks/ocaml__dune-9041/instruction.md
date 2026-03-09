When running Dune rules with sandboxing enabled (e.g. `dune build … --sandbox copy`), some rules that include internal Dune actions (actions implemented by Dune itself rather than external processes) currently prevent the entire rule from being sandboxed if those internal actions are considered “not needing sandboxing”. This results in mixed execution where part of the rule effectively runs outside the sandbox, allowing the rule to observe or reuse files from the workspace/build directory in a way that breaks correctness.

The problem is visible with rules that use `(diff? <src> <corrected>)` inside a `(progn …)` where `<corrected>` is produced earlier in the same action (for example via `(bash "echo … > text-file-corrected")`). When sandboxing is requested, the rule should still be fully sandboxed and `diff?` should compare the build outputs produced within that sandboxed execution. The build should fail with an error like:

`Error: Files _build/default/text-file and _build/default/text-file-corrected differ.`

and `dune promote` should then successfully promote `_build/default/text-file-corrected` back to `text-file`.

Currently, because internal actions may disable sandboxing for the whole rule, Dune can end up consulting a pre-existing `text-file-corrected` from the workspace/build context (even though the second argument of `diff?` is not declared as a dependency and is intended to behave like an intermediate). This can cause inconsistent behavior: a rule can fail (or appear to succeed) depending on whether `text-file-corrected` happens to exist from a previous build, and repeated builds can become incorrectly cached or “fixed” by stale artifacts.

Fix Dune so that internal actions no longer prevent sandboxing of the containing rule: when sandboxing is requested/required for the rule, internal Dune actions must execute under the sandbox as well (even if they wouldn’t strictly require it). With this change:

- Running a rule containing `(diff? text-file text-file-corrected)` under `--sandbox copy` must behave the same as without sandboxing, except that it must not be influenced by stray `text-file-corrected` artifacts outside the sandbox.
- If `text-file-corrected` is produced as part of the rule action and differs from `text-file`, the build must fail with the “Files … differ” error, and `dune promote` must promote the corrected file.
- Builds must not become incorrectly cached due to actions observing undeclared files; sandboxing should correctly isolate actions so that improperly declared dependencies don’t silently affect subsequent builds.

The key behavioral requirement is: selecting sandboxing for a rule must apply to the entire action execution, including any internal Dune actions, so that sandboxing reliably enforces isolation and reproducible results.