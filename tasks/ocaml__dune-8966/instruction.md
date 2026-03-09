Dune’s Coq integration is broken when building projects in `(stdlib no)` mode on systems where only `coq-core` is installed (no `coq-stdlib`). Starting with Dune 3.8.0, Dune runs `coqc --config` during setup, and if `coqc --config` exits with status 1 (which happens when the stdlib is not installed), Dune treats this as a hard failure. This prevents building even minimal Coq theories that explicitly avoid the stdlib/prelude.

Reproduction scenario:
- Environment: `coq-core` installed, `coq-stdlib` not installed.
- A project declares a `coq.theory` with flags that avoid initializing the stdlib, e.g. `-noinit` (or otherwise intends to use Coq without the standard library).
- Running `dune build` fails early with Coq errors like:
  "cannot guess a path for Coq libraries; please use -coqlib option or ensure you have installed the package containing Coq's stdlib ... If you intend to use Coq without a standard library, the -boot -noinit options must be used." (and the build stops).

Expected behavior:
- Building a simple Coq theory that does not require the stdlib should succeed even if `coqc --config` fails.
- If `coqc --config` fails during the build’s attempt to discover installed theories, Dune should not abort the build; it should skip installed-theory discovery and continue with a best-effort configuration (as if there are no installed theories).
- In this situation, Dune should emit a warning explaining that installed theories are being skipped because `coqc --config` failed, including:
  - the exact command that failed (`coqc --config`),
  - the exit code,
  - and a hint to run `coqc --config` manually to see the underlying error.

Additional required behavior around version/config queries:
- Dune must be able to obtain the Coq version using `coqc --print-version` even in environments without the stdlib; calling `coqc --print-version` should use `-boot` so it works with only `coq-core` present.
- When expanding Coq macros that require config (e.g. `%{coq:version}`), if `coqc --config` fails, the expansion should fail with a clear error message of the form:
  "Error: Could not expand %{coq:version} as running coqc --config failed."
  followed by the command failure details and a hint that `coqc --config` requires the `coq-stdlib` package to function properly.
- When expanding `%{coq:version}`, if `coqc --print-version` fails, Dune should fail with an error like:
  "Error: Could not parse coqc version:"
  followed by the command failure details (exit code and command line).
- When expanding config-derived macros such as `%{coq:coqlib}`, a failing `coqc --config` must still be treated as a hard error (since the requested value cannot be determined), with an actionable message indicating that `coqc --config` failed.

In short: make Coq builds resilient to `coqc --config` failure when config is only being used for optional installed-theory discovery, but keep `--config` failures fatal when the user requests config-derived values; also ensure Coq version probing works without stdlib by using `-boot` for `coqc --print-version`.