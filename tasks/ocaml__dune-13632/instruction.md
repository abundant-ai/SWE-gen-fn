In Rocq integration, running Rocq files as part of Dune builds currently always streams Rocq’s standard output to the terminal and does not support “golden/expected output” testing. This makes it impossible to write output-based tests where Rocq’s printed messages (e.g., the result of `Locate nat.` or messages produced in `-test-mode`) are captured and compared against an expected file.

Add support for expected-output tests for Rocq theories and extractions:

When a Rocq source file `X.v` that is part of a `rocq.theory` (or `rocq.extraction`) has a sibling file `X.expected`, Dune should treat `X.v` as an expected-output test when running the `runtest` alias:

- Rocq’s standard output for building/checking `X.v` must be captured to a file `X.output` (in the build context), rather than being printed to the terminal during `dune runtest`.
- `dune runtest` must compare (`diff`) `X.output` against `X.expected`.
- If `X.expected` is missing, behavior should remain unchanged (normal output streaming, no diff-based test).
- If `X.expected` exists but differs from produced output, `dune runtest` must fail with a diff-style error that clearly indicates the expected file and produced output file (using the conventional `--- X.expected` / `+++ X.output` style headers), and exit with a non-zero status.
- `dune promote` should promote the produced output to the expected file so that rerunning `dune runtest` succeeds. The promotion message should indicate that `_build/.../X.output` is being promoted to `X.expected`.

Behavioral details that must work:

- This should work whether modules are implicit or explicitly listed via `(modules ...)` in `rocq.theory`.
- It must support qualified subdirectories (e.g., `sub/bar.v` with `sub/bar.expected`) and still produce the corresponding `sub/bar.output` and diff against `sub/bar.expected` under `dune runtest`.
- When Rocq is invoked with flags such as `-test-mode`, the captured output must include the resulting messages (including multi-line error/report text) exactly as printed by Rocq, so that it can be matched against `.expected`.
- For `rocq.extraction`, warnings or messages emitted by Rocq may still appear on the terminal (e.g., warnings on stderr), but the captured stdout that is diffed must be the Rocq standard output content relevant to the `.expected` comparison; if `.expected` exists for an extraction file, `dune runtest` should still perform the expected-output diff and allow promotion.

After implementing this, a workflow like the following should work end-to-end:

1) Create `foo.v` and an empty `foo.expected`.
2) Run `dune runtest` and observe a failing diff that shows the produced Rocq output being added.
3) Run `dune promote` to update `foo.expected` from `foo.output`.
4) Run `dune runtest` again and see it succeed without printing the captured stdout to the terminal.