When converting opam packages into dune lockfiles / package definitions, several classes of errors are reported without a useful source location. This makes failures hard to diagnose because the error message doesn’t point at the relevant file (e.g., the package’s opam file or the opam repository directory being accessed).

Fix error reporting so that conversion-related errors include a concrete location pointing to the most relevant file or directory involved in the failure.

1) Unix I/O error while copying package “files/” from an opam repository

If a package contains a `files/` directory in the opam repository and dune encounters a Unix error while reading/copying it (for example, the directory is not readable due to permissions), the error must be reported with a location pointing at the opam repository path that caused the failure.

Example scenario: the directory `<opam-repo>/packages/<pkg>/<pkg>.<ver>/files/dir` is missing read permission, and conversion tries to read it.

Expected output format (location must be present and must reference the failing repository path):

```
File "<opam-repo>/packages/<pkg>/<pkg>.<ver>/files/dir", line 1, characters 0-0:
Error: Unable to read file in opam repository:
opendir(<opam-repo>/packages/<pkg>/<pkg>.<ver>/files/dir): Permission denied
```

Currently, the error is raised but the location is missing or not tied to the repository path; update the error so it consistently attributes the failure to that directory.

2) Unsupported opam variables used in command conversion

When converting opam commands that reference variables which are explicitly unsupported, dune must fail with an error message that:
- includes a location pointing to the package’s `opam` file, and
- states exactly which variable is unsupported.

For each of the following variable references, the error must be:

```
File "<opam-repo>/packages/<pkg>/<pkg>.<ver>/opam", line 1, characters 0-0:
Error: Variable "<var>" is not supported.
```

Variables that must be handled this way include (at minimum):
- `opam-version`
- `root`
- `_:hash` (must report `hash`)
- `_:build-id` (must report `build-id`)
- `misc` and `_:misc` (must report `misc`)
- `_:depends` (must report `depends`)
- `_:build` (must report `build`)
- `_:opamfile` (must report `opamfile`)

Currently, these failures may not be attributed to the opam file location or may not consistently format the variable name; make the location and message consistent.

Overall, ensure that conversion errors provide the best-available location even when an exact span inside the file is not known: it’s acceptable to use `line 1, characters 0-0`, but the `File "..."` portion must identify the relevant opam file or repository path involved in the failing operation.