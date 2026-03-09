`dune pkg` currently ignores the `patches:` field from opam package metadata, so packages that rely on patches are built without applying them. This causes builds to use unpatched sources (e.g., files still contain old contents like "This is wrong" instead of the patched "This is right"), and there is no way to express patch application in the generated lock package build steps.

Implement patching support end-to-end:

When an opam package includes `patches: [ ... ]`, solving/generating the lock directory must (1) include those patch files in the lock package’s associated files area (preserving subdirectories like `dir/bar.patch`), and (2) inject patch application steps into the lock package build description so that the patches are applied before subsequent build commands run.

The lock package build stanza should include explicit `(patch <path>)` actions for each patch in the same order as listed in the opam file. For example, for `patches: ["foo.patch"; "dir/bar.patch"]`, the generated build should apply `foo.patch` and then `dir/bar.patch` before running the rest of the build commands.

Additionally, support applying patches directly as a package build action via a patch action that can be used in a build `(progn ...)` sequence. This patch action must successfully apply unified diffs that:
- modify an existing file (including files in subdirectories),
- create a new file (diff against `/dev/null`), and
- delete an existing file (diff to `/dev/null`).

A key correctness requirement is that patch application must work even when the files being patched are symlinks: before applying the patch, any symlink targets that would be modified must be materialized so the patch updates real file contents rather than failing or patching through symlinks unexpectedly.

Expose the patch execution entrypoint used by the package build system as `Dune_patch.exec` (and for tests/consumers, `Dune_patch.For_tests.exec`), taking parameters equivalent to: a display mode, the patch file path (`~patch`), the working directory (`~dir`), and a destination for stderr. Running this on a directory containing the relevant files and the patch file should result in the patched filesystem state described by the diff.

After these changes:
- Building a lock package that includes `(patch foo.patch)` followed by `(system "cat foo.ml")` should output the patched file contents.
- Solving a project that depends on an opam package with `patches:` should produce a lock package description that contains the patch actions, and building that package should use the patched sources (e.g., `cat foo.ml` prints the patched content).