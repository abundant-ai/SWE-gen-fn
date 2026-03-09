When building or packaging a Dune project in release mode, the project’s lock directory (e.g., `dune.lock/`) is currently treated as part of the package sources and its contents can affect the build. This is a problem for projects that commit their lock directory: when users build/install via opam (or any workflow that uses Dune’s release/package mode), files inside `dune.lock/` may get included and evaluated, potentially changing build behavior unexpectedly.

Dune should ignore the lock directory by default in release workflows. Specifically:

1) `dune build @install --release` must ignore the `dune.lock/` directory entirely. If the lock directory contains files that would otherwise be interpreted during the build (for example, a package file under `dune.lock/` that defines a build action), those actions must not run in `--release` mode.

2) Add a new command-line option `--ignore-lock-directory` that, when provided, always causes Dune to skip/ignore the lock directory, regardless of other settings.

3) `--release` must imply `--ignore-lock-directory` (and the same implied behavior must apply to `-p` / package build mode).

Reproduction example:
- Create a project with a committed `dune.lock/` directory.
- Put a file under `dune.lock/` that would trigger observable build behavior if it were processed (e.g., a build stanza that runs `echo`).
- Run `dune build @install --release`.

Expected behavior: the build succeeds without considering anything under `dune.lock/`, and no actions defined solely under `dune.lock/` are executed.

Actual behavior (current): release builds do not ignore `dune.lock/`, so content in the lock directory can be included and affect the build.

Implement the option and the implied defaults so that release/package mode reliably excludes the lock directory from package sources and from any evaluation during the build.