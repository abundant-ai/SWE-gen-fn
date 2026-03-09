When loading or describing a package lockdir, Dune currently does not validate that every dependency listed by a locked package is itself present as a package in the same lockdir. This allows a corrupted or user-tampered lockdir to appear valid even though the package graph references missing nodes.

Reproduction example:
1) Create a lockdir containing packages a, b, c where a depends on b, b depends on c.
2) Modify c’s metadata so it depends on a missing package, e.g. add dependency d (so c depends on a and d) without adding a corresponding locked package entry for d.
3) Run `dune describe pkg lock` (or any command that loads the lockdir).

Expected behavior: Loading the lockdir must fail with a clear diagnostic pointing at the offending locked package file and the specific missing dependency. The error should include messages of the form:
- `The package "c" depends on the package "d", but "d" does not appear in the lockdir dune.lock.`
Then it should terminate with a summary error:
- `Error: At least one package dependency is itself not present as a package in the lockdir dune.lock.`
And provide a hint:
- `Hint: This could indicate that the lockdir is corrupted. Delete it and then regenerate it by running: 'dune pkg lock'`

If multiple dependencies are missing (for example, after removing package a from the lockdir and also having c depend on d), all missing-dependency diagnostics should be reported (e.g. both missing a and missing d), followed by the same summary error and hint.

Actual behavior: The lockdir loads successfully (or fails later/unclearly), and missing package dependencies inside the lockdir are not detected or not reported with the above actionable message.

Implement validation during lockdir load/creation so that for each locked package, all declared dependencies must correspond to packages present in the lockdir; otherwise emit the diagnostics above and fail the command with a non-zero exit code.