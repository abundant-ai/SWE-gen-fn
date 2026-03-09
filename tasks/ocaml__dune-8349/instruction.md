Dune’s `(install ...)` stanza should support installing an entire directory tree from the source workspace into the selected install `section` via a new field, so users can write:

```lisp
(install
 (section doc)
 (source_trees mydocs))
```

Currently, Dune does not correctly support installing source directory trees through `source_trees` (including validating existence and emitting the correct entries in the generated `.install` file). Implement support for `source_trees` so that:

1) When a user specifies a source directory that does not exist, `dune build <pkg>.install` fails with an error pointing at the `source_trees` entry and the message:

`Error: This source directory does not exist`

2) When the source directory exists, Dune generates install entries for every file under that directory recursively (including nested subdirectories). For example, if `mydocs/` contains:

- `mydocs/foo.md`
- `mydocs/baz.md`
- `mydocs/foo/bar.md`

then the generated install description for section `doc` installs them under the package’s doc destination, preserving the relative paths beneath the source tree root (so `foo/bar.md` remains in `foo/bar.md` under the destination).

3) `source_trees` must support an aliasing form `(SRC as DST)` where the destination path prefix changes from `SRC/` to `DST/` while still recursively installing all files and preserving their internal relative paths. The following cases must work:

```lisp
(source_trees (mydocs as yourdocs))
(source_trees (mydocs as your/docs))
```

and they should install to `.../doc/<pkg>/yourdocs/...` and `.../doc/<pkg>/your/docs/...` respectively (with files like `baz.md`, `foo.md`, `foo/bar.md` mapped under that destination).

4) The alias destination may also include `..` path segments, e.g.:

```lisp
(source_trees (mydocs as ../))
```

In this case, the installed paths should reflect that destination prefix (for instance `../baz.md`, `../foo.md`, `../foo/bar.md`) rather than being forced to remain under the package’s doc subdirectory.

Overall, `source_trees` should behave as a directory-tree analogue of installing individual files: validate the source directory exists, enumerate files recursively, and emit correct install mappings (source file -> destination relative path) respecting any `(as ...)` destination prefix.