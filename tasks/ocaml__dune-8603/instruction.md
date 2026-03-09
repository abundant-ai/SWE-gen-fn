`dune init` incorrectly validates the `--public` argument as if it were a Dune component/library name rather than a public name (opam package name with optional dot-separated suffixes). As a result, valid public names containing dashes (and other characters allowed by opam package naming rules) are rejected.

Reproduction:

```sh
$ dune init lib mirage_pair --public mirage-pair
```

Current behavior: the command fails with an error like:

```
dune: option '--public': invalid component name `mirage-pair'
Library names must be non-empty and composed only of the following
characters: 'A'..'Z', 'a'..'z', '_' or '0'..'9'.
```

Expected behavior: `--public` should accept valid public names, including opam package names containing `-` (and other opam-allowed characters such as `_` and `+`), and should also accept optional dot-separated suffixes. For example, these should succeed:

- `dune init lib foo_bar --public foo-bar`
- `dune init lib lib_s1_s2 --public lib.sub1.sub2`

Additionally, invalid public names should be rejected with an informative message describing the public-name rules (not the component-name rules). For example, passing a syntactically invalid public name such as `--public "some/invalid&name!"` should fail with an error message explaining that public names are composed of an opam package name and optional dot-separated suffixes, and that package names can contain letters, numbers, `-`, `_` and `+`, and must contain at least one letter.

Finally, when `--public` is provided without an explicit value (so the public name is implicitly derived from the library/executable name), that derived value must still be validated as a public name and produce the same public-name-specific error if it is not valid (e.g., `dune init lib 0 --public` should fail with the public-name validation error, since `0` is not a valid opam package name because it contains no letter).