Dune can crash with an internal error when consuming a findlib package whose META file declares an empty version string. In particular, some packages may contain metadata like `version=""`, and due to how findlib variables are expanded, the version can be obtained as `Some ""` rather than being absent.

When Dune converts the findlib package information into its internal representation, it attempts to build a `Package_version.t` from this value. An empty string is not a valid `Package_version.t`, so Dune raises an internal error:

```
("Invalid Package_version.t", { s = "" })
```

This can occur during `dune build`/`dune exec` when the project links against such a library.

Expected behavior: an empty findlib version string should be treated as “no version”. Dune should not raise an internal error, and any API that exposes the library version (for example via `Build_info.V1.Statically_linked_library.version`) should return `None` for that library when its META version is the empty string.

Actual behavior: Dune treats the empty string as a present version and attempts to convert it, which triggers the `Invalid Package_version.t` internal error.

Fix Dune so that when a findlib package version is `Some ""`, it is normalized to `None` before any conversion to `Package_version.t`, preventing the crash and ensuring version-reporting APIs behave as “no version” in this case.