Package dependencies break when an installed artifact is a directory target rather than a regular file. When a package installs a directory (for example, installing the output of a directory target into the `share` section), the package’s `dune-package` metadata currently records only the directory path in the `(files ...)` listing as if it were a file. Later, when another project uses `(package foo)` in a dependency context, Dune attempts to treat that recorded path as a regular file and fails with an error like:

```
Error: File unavailable:
/path/to/share/X
This is not a regular file (S_DIR)
```

The package metadata and `(package ...)` dependency expansion need to distinguish files from directories.

Implement support for recording installed directories explicitly in `dune-package` files by allowing a `(dir PATH)` entry within the `(files ...)` field. When a package’s installed contents include a directory target, the generated `dune-package` should record that entry as a directory (e.g. `((dir bar))` under the appropriate section) rather than as a plain file.

When expanding `(package foo)` dependencies, directory entries recorded as `(dir PATH)` must expand to the recursive contents of that installed directory so that depending on the package brings in the actual files under the directory (including nested subdirectories), and does not attempt to treat the directory itself as a file.

Expected behavior:
- Generating `dune-package` for a package that installs a directory should record that directory using `(dir ...)` in the `(files ...)` field.
- Installing the package should install all files contained within the directory recursively.
- A separate project that declares a dependency such as `(deps (package foo))` (or equivalent use of `(package foo)`) should build successfully, with the dependency resolving to the recursive set of installed files, and without raising “This is not a regular file (S_DIR)”.

Actual behavior to fix:
- The `dune-package` lists the directory path as a file, and `(package ...)` expansion later fails when it encounters a directory where it expects a file.