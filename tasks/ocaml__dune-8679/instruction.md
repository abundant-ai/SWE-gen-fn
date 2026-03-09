Package installation entries are currently interpreted relative to the wrong directory, which causes paths referenced in a generated `.install` file to be resolved incorrectly.

Reproduction scenario: a package build step generates a `test.install` file inside the package’s directory (e.g., under `dune.lock/<pkg>/`) and that install file contains an entry such as:

```
bin: [ "?_build/install/default/bin/foo" ]
```

Expected behavior: all entries inside the `.install` file must be interpreted relative to the directory containing that `.install` file (i.e., the install file’s own path). In the example above, `?_build/install/default/bin/foo` should be resolved as a build-path reference from the install file’s directory, and the package installation should succeed and install `foo` into the `bin` section.

Actual behavior: entries are interpreted relative to a different directory (typically the workspace root or another context), so build-path entries like `?_build/...` are resolved incorrectly. This leads to the package install step failing to find the referenced artifact and thus failing the package build/install.

Fix requirement: update the package install parsing/interpretation so that when reading an install file for a package, every path entry in every section (e.g., `bin`, `lib`, etc.) is resolved relative to the install file’s directory, not the process working directory or workspace root. Build-path-prefixed entries (e.g., those starting with `?`) must also follow this rule, so that `_build/...` references work when the install file is generated within the package directory.