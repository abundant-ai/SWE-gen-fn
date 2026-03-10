When using Dune rules that run a `(diff <expected> <actual>)` action, Dune currently does not correctly distinguish between an *empty* expected file and a *missing* expected file. This leads to confusing diffs and incorrect handling of promotion targets when the expected path does not exist yet (including when the expected path is inside a directory that doesn’t exist).

Reproduction example:

```lisp
(rule
 (action
  (progn
   (with-stdout-to foo (echo baz))
   (diff dir/foo foo))))
```

If `dir/foo` does not exist, running `dune build ./foo --diff-command <cmd>` should invoke the diff command with the first argument pointing to `/dev/null` (meaning “missing file”) and the second argument pointing to the generated file `foo`. The error output should identify the missing reference file and show the diff command seeing `/dev/null` as the left side.

After that, `dune promote` should succeed and create `dir/foo` even if `dir/` didn’t exist, printing a message indicating that `_build/default/foo` is being promoted to `dir/foo`.

Additionally, when diffing against a *non-existent* reference file, Dune should behave as if the reference is an empty file for the purposes of deciding whether to report a difference and what diff output to display:

- If the generated file is also empty, the diff should be treated as no difference (no failure).
- If the generated file is non-empty, Dune should report a diff against an empty baseline (i.e., show the generated content as added from an empty file) rather than treating the reference as an existing file with content.

Current behavior: Dune may treat missing and empty reference files as the same thing (or pass an incorrect path to the diff command), which results in misleading diffs and can prevent correct promotion behavior when the target file or its parent directory does not exist.

Fix the diff action so it correctly distinguishes “missing file” vs “empty file”, passes the appropriate placeholder (`/dev/null`) to external diff commands when the reference file is missing, and ensures `dune promote` can promote into non-existent directories and create the missing target file in these scenarios.