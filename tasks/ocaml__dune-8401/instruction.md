Findlib handling is doing unnecessary repeated work and has inconsistent configuration plumbing, which causes incorrect/unstable package resolution behavior in some contexts. A Findlib instance should be memoized per build context so repeated calls don’t rebuild state, and the Findlib configuration should use the external library extension (ext_lib) directly rather than relying on Lib_config being threaded through.

The public/tested behavior that must work is:

- It must be possible to construct a Findlib instance for tests via `Findlib.For_tests.create ~paths ~lib_config` and then resolve packages with `Findlib.find findlib (Dune_lang.Lib_name.of_string "<name>")`.
- For a package `qux`, `Findlib.find` must return a library whose `Lib_info.archives` report byte archives as `["/qux/qux.cma"]` and native archives as `[]`.
- For a package `xyz`, `Findlib.find` must return a library whose `Lib_info.archives` report byte archives as `["/xyz.cma"]` and native archives as `[]`.
- META “requires” handling must be correct for predicates: given a META where `requires = "bar"` and `requires(ppx_driver) = "baz"`, the resolved library `foo` must have `Lib_info.requires` equal to `["baz"]` (i.e., the predicate-specific requires must take effect as expected).

Additionally, internal API cleanup is required:

- Replace the use of `Lib_config` inside Findlib configuration with `ext_lib` (the external library extension string) so that Findlib no longer depends on a full `Lib_config` record for this purpose.
- Remove `Findlib.DB` as a standalone module and ensure any callers are updated to use the remaining Findlib interfaces without behavior regressions.

After these changes, repeated operations that need Findlib for the same context (including sparse features like `Sites.create`) must reuse the same memoized Findlib instance rather than recomputing it, while preserving the package resolution and META parsing behaviors described above.