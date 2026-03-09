Dune’s `(install (files ...))` stanza supports installing files specified via `(glob_files ...)` and `(glob_files_rec ...)`. Today, the destination path for each matched file is derived from the glob’s own prefix (the portion of the glob pattern before the `*`). This becomes problematic when the glob begins with a relative parent path like `../stuff/*.txt`: the computed install destination can begin with `..`, which causes Dune to emit warnings about install destinations escaping the package’s install directories.

Implement a new optional `with_prefix` keyword for `glob_files` and `glob_files_rec` entries in install stanzas that lets users override the destination prefix used for installed paths.

The syntax should allow a glob expression to be written with an explicit destination prefix, for example:

- `(glob_files (*.txt with_prefix bar))` should install all matched `*.txt` files under `bar/` in the chosen install section.
- `(glob_files_rec (../stuff/*.txt with_prefix stuff))` should install files matched from `../stuff/*.txt` (recursively) but place them under `stuff/` (e.g., `stuff/foo.txt`, `stuff/xy/bar.txt`) rather than preserving the `../stuff/` prefix.

This feature must be gated by the Dune language version:

- When `(lang dune 3.10)` is used, any use of `with_prefix` in this context must fail with an error of the form:
  `Error: This syntax is only available since version 3.11 of the dune language. Please update your dune-project file to have (lang dune 3.11).`
- When `(lang dune 3.11)` (or newer) is used, the syntax must be accepted and affect installation destinations as described.

Behavioral requirements for `with_prefix`:

- It must work for both `glob_files` and `glob_files_rec` used inside an install stanza.
- The provided prefix may be a path like `bar` or `txt`, may be `.` to indicate “no extra directory”, and may contain pforms/variable expansions (e.g. `%{read:prefix}`) that evaluate to a path.
- The installed destination paths recorded for each file should reflect the chosen prefix. For example, when using `with_prefix bar`, the destination for `a.txt` should be `bar/a.txt`.
- Multiple glob entries in the same `files` field may each use their own `with_prefix` and should not interfere with one another.

This change is motivated by cases where using `../` in a glob is necessary to select files but should not force the install destination to begin with `..`. With `with_prefix`, users should be able to avoid generating install destinations that start with `..` (and thereby avoid the corresponding deprecation warnings about destinations beginning with `..`).