Running Dune with package scoping is incorrect in the presence of cram tests when packages use a `(dir ...)` field in the `dune-project` package definitions. In particular, `dune build @install -p <pkg>` (and similarly `dune runtest --only-packages <pkg>`) can end up considering cram tests that live in other packages’ source-tree directories, because cram tests are discovered directly from the source tree and are not being assigned to packages using the same directory scoping rules as other stanzas.

Dune should respect the `dir` field of each package when deciding which package a cram test belongs to, and when filtering by packages.

Reproduction scenario:
- A project defines multiple packages in `dune-project`, each with an exclusive directory, e.g. package `foo` has `(dir foo)` and package `bar` has `(dir bar)`.
- Each directory contains cram tests (e.g. `foo/file.t`, `foo/dir.t/run.t`, `bar/file.t`, `bar/dir.t/run.t`).
- When running `dune runtest --only-packages foo`, only the cram tests under `foo/` should run; cram tests under `bar/` must not be selected.

Additionally, Dune must enforce that a cram stanza in an exclusive package directory cannot claim a different package than the one that owns that directory. For example, if directory `foo/` is exclusive to package `foo`, then a stanza like `(cram (package bar))` in `foo/` must fail with an error indicating that `bar` may not be defined there and that only `foo` is allowed because the directory is exclusive to `foo`. A redundant declaration `(cram (package foo))` in `foo/` should be accepted.

Expected behavior:
- `dune runtest --only-packages foo` only runs cram tests located under the directory assigned to package `foo` via `(dir ...)`.
- `dune build @install -p foo` is not broken by the presence of cram tests in other packages’ directories.
- Declaring `(cram (package <other>))` inside a directory that is exclusive to a different package is rejected with a clear error message explaining the exclusivity constraint.

Actual behavior:
- Cram tests are not consistently assigned to packages using the package `(dir ...)` scoping, so package-filtered builds/tests may include or be affected by cram tests from other packages, and invalid package declarations in cram stanzas may not be rejected correctly in exclusive directories.