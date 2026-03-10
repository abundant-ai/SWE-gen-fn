Rocq “expected output” support is being exercised even when a project has not enabled the Rocq extension at the required language level, causing incorrect behavior in projects that use rocq stanzas without a proper `(using rocq 0.12)` declaration.

Currently, Dune may attempt to run Rocq-related output/expected-file test logic (producing `.output` files and diffs against `.expected`) without first confirming that the project language enables Rocq at version 0.12. In these cases, instead of cleanly rejecting Rocq stanzas as unavailable, Dune proceeds far enough that users can see confusing/incorrect output expectations being triggered.

The behavior should be gated on the project language declaration: Rocq output/expected tests must only be enabled when the project explicitly opts in with a dune-project or workspace stanza equivalent to:

```lisp
(lang dune 3.22)
(using rocq 0.12)
```

When Rocq is not enabled, any use of Rocq stanzas such as `(rocq.theory ...)` must fail early with the standard error message indicating that the stanza is only available when Rocq is enabled, e.g.:

```
Error: 'rocq.theory' is available only when rocq is enabled in the
 dune-project or workspace file. You must enable it using (using rocq 0.12) in
 the file.
```

Once Rocq is enabled at `(using rocq 0.12)`, Dune should support the “expected output” workflow for `.v` sources:

- Running `dune runtest` should compare `<name>.expected` with `<name>.output` and report a unified diff when they differ.
- Running `dune promote` should promote `_build/default/<name>.output` into `<name>.expected`.

This gating must apply consistently across Rocq features that emit output suitable for expected-file testing, including:
- `rocq.theory` rules that produce `.output` files for `.expected` comparisons
- `dune rocq top` invocation behavior when run from different directories
- `rocq.extraction` workflows where runtest compares `extract.expected` with `extract.output` (while still printing any Rocq warnings produced during the build/run)

After the fix, projects without `(using rocq 0.12)` should never enter Rocq output/expected-test mode; they should instead reliably produce the “rocq.theory is available only when rocq is enabled…” error when Rocq stanzas are present. Projects with `(using rocq 0.12)` should continue to have working expected-file diffs and promotion behavior.