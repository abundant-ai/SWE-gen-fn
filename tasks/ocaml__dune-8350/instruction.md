Dune currently allows entries in an `(install ...)` stanza to produce install destinations whose relative paths begin with `..` (or are exactly `..`). This permits installed files to “escape” the package’s install directory (for example, installing into a sibling directory under `_build/install/...`), which is a regression reported in Issue #2123 and was introduced by earlier install/destination handling changes.

When generating a package’s `.install` file (e.g. via `dune build <pkg>.install`), Dune must ensure that the destination path for every installed file/directory does not start with `..` after all expansions and mapping rules have been applied. Today, Dune only emits a deprecation warning in some cases; the bug is that these escaping destinations are still accepted and end up producing `.install` entries whose destination is outside the package’s install directories.

Reproduction example:

```lisp
(lang dune 3.11)
(package (name foo))

(install
 (section etc)
 (files (a/b.txt as ../b)))
```

Building `foo.install` currently succeeds and yields an install destination derived from `../b`. The expected behavior is that destinations beginning with `..` are rejected (or, if the compatibility policy requires it, at least reliably detected and surfaced as a warning/error at the correct location), because such destinations can escape the package’s install directories.

This validation must also apply to:

1) `(dirs (src as <dst>))` entries where `<dst>` begins with `..` or equals `..`, including cases where the `..` appears after variable expansion.

2) Glob-based install sources, such as `glob_files_rec`, where the matched file paths can imply a destination beginning with `..` (e.g. a glob pattern like `../stuff/*.txt` causing destinations like `../stuff/foo.txt`). These cases must be detected for each matched destination path.

At the same time, Dune should still allow users to install files matched by globs into a different subdirectory *without* using `..`. Introduce/support a way to rewrite the destination prefix for glob matches so that users can map a source prefix to a different install prefix while keeping destinations within the package’s install directories. For example, the following should be accepted and should install all matches under `new/path/...` rather than preserving `some/path/...`:

```lisp
(install
 (section share)
 (files (glob_files (some/path/* with_prefix new/path))))
```

Expected behavior of `with_prefix`:

- For each path matched by the glob, replace the leading `some/path` portion of the match with `new/path` to form the install destination.
- The resulting destination must be validated under the same “must not begin with `..`” rule.

Error/warning messaging requirements:

- When an escaping destination is detected, Dune must point at the offending destination path text and report that the destination path begins with `..` and is disallowed because it can escape the package’s install directories.
- For glob installs that expand to multiple destinations beginning with `..`, each offending destination should be reported consistently (or otherwise clearly summarized) so it’s apparent which expanded paths are invalid.

Overall, after this change it should no longer be possible for an install stanza to produce destinations that start with `..`, whether via explicit `(… as ../…)`, via directory installs, via glob expansion, or via variable expansion. The new `with_prefix` glob feature should provide a supported way to redirect glob destinations without relying on `..`.