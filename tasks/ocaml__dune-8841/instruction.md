`dune describe` does not currently support describing packages from lock directories/lock files, but it should.

Add a new subcommand `dune describe pkg lock` that prints the packages contained in a lock file. When run with no explicit lock file arguments, it should default to describing the workspace’s default lock file and print a header followed by one package per line.

Expected behavior:
- Running `dune describe pkg lock` prints:
  - A header line exactly of the form `Contents of <lockfile>:` (for the default lock file, this should be `Contents of dune.lock:`).
  - Then a list of packages contained in that lock file, one per line, formatted as `<name>.<version>` (for example `A.1.2.0`, `B.2.1+rc1`, `D.0.4.0.beta1`, `E.3.0~alpha1`).
- Running `dune describe pkg lock <lock1> <lock2> ...` prints the same kind of output for each provided lock file, in the order the arguments are provided. For each lock file, print its own `Contents of ...:` header followed by the package list.

Problem to solve:
- The command `dune describe pkg lock` (and its variant with explicit lock file arguments) must exist and work on lock directories/lock files produced by Dune’s package solver.
- The output must be a “nice pretty printed list” of the packages inside the lock file, including their versions using the `<name>.<version>` format.
- The command must support pre-release/build-like version strings (examples include `2.1+rc1`, `0.4.0.beta1`, `3.0~alpha1`) and print them verbatim as part of `<name>.<version>`.

If a workspace has multiple contexts producing multiple lock files, the command should still behave correctly:
- With no args: describe the default `dune.lock`.
- With explicit args: allow describing non-default lock files such as `foo.lock`.

The implementation should reuse existing package pretty-printing where appropriate so that the package listing format is consistent with other `dune pkg`/describe outputs.