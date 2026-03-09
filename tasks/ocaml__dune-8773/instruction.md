Users want a way to see which packages recorded in a project’s lockdir are out of date compared to the configured opam repositories, without modifying the workspace. Add a new command `dune pkg outdated` that inspects the current lockdir(s) and reports which locked packages have a newer available version in the configured opam repositories.

When running `dune pkg outdated --opam-repository-path=<path>`, if all locked packages are already at the best available version, the command should print a concise message indicating the lockdir is up to date (e.g. `dune.lock is up to date.`) and exit successfully.

If any locked packages are not the best available version, the command should print a summary line of the form:
`<n>/<total> packages in <lockdir> are outdated.`
followed by one line per outdated package:
`- <name> <locked_version> < <newest_version>`

By default, the command should only list outdated packages that are immediate dependencies of local packages (not merely transitive dependencies). If there exist additional outdated packages that are only transitive, the output must include an extra hint line between the summary and the package list:
`Showing immediate dependencies, use --transitive to see them all.`

If the user passes `--transitive`, then all outdated packages (including transitive dependencies) must be listed, and the hint line must not be printed.

The command must support `--all-contexts`. When `--all-contexts` is passed, it should check every relevant lockdir (e.g. both `dune.lock` and `dune.workspace.lock` when present) and print results for each, prefixed in a consistent way (for example lines beginning with `- ` and indented sub-lines), while preserving the same semantics for up-to-date vs outdated, default immediate-only vs `--transitive`, and error handling.

Error handling: if, during the check for a given lockdir, one or more packages referenced by the lockdir cannot be found in the configured opam repositories, the command should still print any successful outdated results it can compute, but then print a clear error message afterwards indicating that the packages were not found, and exit non-zero. The error message must identify:
- which lockdir was being checked (e.g. `When checking dune.lock, ...`)
- the list of missing packages (one per line, prefixed with `- `)
- the repositories that were searched

Ordering requirement: when both normal results and errors occur in one run (e.g. one package can be checked and another is missing from repos), any error block must appear after the outdated summary/list.

Also provide a reusable explanation/formatting function that can be exercised independently: `Dune_pkg_outdated.For_tests.explain_results ~transitive ~lock_dir_path results` should generate the human-readable message lines described above from a list of result items (where each result indicates either “package is best candidate” or “better candidate exists”, and whether the package is an immediate dependency of a local package). The produced message should apply appropriate console styles to emphasize important parts (e.g. headline vs details), but must remain readable when styles are stripped.

Overall, `dune pkg outdated` must be read-only (must not change lockdirs or other workspace state) and must consistently compare the locked versions against the best candidate versions available from the configured opam repositories.