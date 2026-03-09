When building targets that are generated via internal promotion rules (notably opam file generation from (generate_opam_files true)), Dune incorrectly modifies files even when the user passes --ignore-promoted-rules.

Reproduction:
1) Create a dune-project using a recent Dune language version (e.g. (lang dune 3.10)) with (generate_opam_files true) and a package definition.
2) Run: dune build foo.opam
3) Manually edit foo.opam and add a distinctive extra line (e.g. "foobar_extra").
4) Run: dune build --ignore-promoted-rules foo.opam

Expected behavior:
With --ignore-promoted-rules enabled, Dune must not apply any promotions and therefore must not overwrite/modify already-present promoted artifacts. In particular, the manually added line in foo.opam must remain present after the build, and Dune should not regenerate and promote a new foo.opam over it.

Actual behavior:
Dune regenerates foo.opam and overwrites the file despite --ignore-promoted-rules, effectively discarding the manual modification.

Fix required:
Ensure that --ignore-promoted-rules consistently disables promotions for both user-defined promote rules and internal promote rules (including opam file generation and other internally generated promoted artifacts). After the fix, invoking dune build --ignore-promoted-rules <promoted-target> should leave the on-disk target unchanged even if Dune can compute a new generated version.

This must also hold in projects that use dune-site and generate site modules/plugins, where some builds involve promote (until-clean) and other promoted outputs: running builds with --ignore-promoted-rules should not cause promoted outputs to be written back into the source tree.