When running Dune with the CLI flag `--ignore-promoted-rules`, Dune should avoid applying any promotion steps that would write generated content back into the source tree. This currently works for user-declared promotion rules, but it does not work for internally-created promotion rules.

A concrete example is internal opam file generation triggered by `(generate_opam_files true)` in `dune-project`. If a generated `<pkg>.opam` file is manually modified (e.g., a user appends a custom line), then running a subsequent build with `--ignore-promoted-rules` should not overwrite or update that file.

Actual behavior: internal promotion still occurs even when `--ignore-promoted-rules` is passed, so files produced by internal promote rules (such as generated opam files) can be rewritten during `dune build`, losing or altering user edits.

Expected behavior: `--ignore-promoted-rules` must suppress promotion for both user-defined and internal promote rules. After a user edits `foo.opam` (for a project with `(generate_opam_files true)` and a `(package (name foo))` stanza) and then runs:

```sh
dune build --ignore-promoted-rules foo.opam
```

the contents of `foo.opam` must remain unchanged (e.g., an appended line like `foobar_extra` must still be present afterward).

Fix Dune so that the flag is honored uniformly for internal promotion actions as well as external/user-specified ones, ensuring that internal rules that would normally promote generated artifacts back into the source tree are ignored when the flag is set.