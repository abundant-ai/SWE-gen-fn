When converting opam package build/install commands into dune actions (e.g., during `dune pkg lock` generation), opam-style variable interpolations of the form `%{var}%` inside command arguments are not handled correctly.

The conversion should support replacing opam variable interpolations with the corresponding dune percent forms (pforms) in the resulting actions. For example, if an opam command contains arguments like `"--prefix=%{prefix}%"` or `"-j%{jobs}%"`, the generated dune action should contain `"--prefix=%{prefix}"` and `"-j%{jobs}"` respectively (i.e., translate `%{...}%` to `%{...}` so dune can interpret it as a pform). This translation must work when the interpolation appears inside a larger string (prefix/suffix text around it), and it must work for multiple interpolations across a command list.

The conversion must also preserve literal percent signs that are not part of opam’s interpolation syntax. For instance, an argument `"%d"` (as in `printf %d 42`) must remain `%d` and must not be modified or treated as an interpolation.

If a command contains a malformed opam interpolation (e.g., an opening `%{` without a matching `}%`, such as `"--prefix=%{prefix"`), the conversion should fail with a clear error indicating that a malformed variable interpolation was encountered while processing commands for that package. The error must include the malformed interpolation text and the full command being processed (shown in a human-readable form similar to how the command appears in the opam file).

Expected behavior examples:
- Converting a build command like `["./configure" "--prefix=%{prefix}%" "--docdir=%{doc}%/ocaml"]` should produce a dune run action equivalent to running `./configure --prefix=%{prefix} --docdir=%{doc}/ocaml`.
- Converting `[make "-j%{jobs}%"]` should produce an action equivalent to running `%{make} -j%{jobs}` (i.e., keep dune’s tool pform for `make` and translate the jobs interpolation).
- Converting a command with a literal percent format string like `["printf" "%d" "42"]` should produce an action that still runs `printf %d 42` with `%d` unchanged.
- Converting a command with malformed interpolation like `["./configure" "--prefix=%{prefix"]` should raise an error of the form:
  `Error: Encountered malformed variable interpolation while processing commands for package <pkg>.<ver>.`
  followed by lines showing the malformed interpolation and the full command.

Implement the interpolation handling in the opam-command conversion logic so that these cases work consistently for both build and install command lists, and ensure errors are raised during lockdir generation when malformed interpolations are present.