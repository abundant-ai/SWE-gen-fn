Library dependency handling in Dune’s language layer is inconsistent after moving the `Lib_dep` abstraction under `Dune_lang`. Code that consumes library metadata (including findlib-based package resolution) expects to work with `Dune_lang.Lib_dep` values and be able to serialize them to dynamic representations for debugging/printing.

Currently, when resolving a package and inspecting its dependency list via `Lib_info.requires`, the dependencies are not represented consistently as `Dune_lang.Lib_dep` values across the codebase. This shows up when attempting to render the dependency list using `Lib_dep.to_dyn`: the produced output is wrong or the code fails to compile/typecheck because some parts still produce/expect the old `Lib_dep` representation.

The system should behave as follows:

- `Dune_lang.Lib_dep` must be the canonical representation for library dependencies throughout the relevant codepaths.
- When reading package metadata that contains conditional requires (e.g. `requires = "bar"` and `requires(ppx_driver) = "baz"`), the simplified/selected dependencies used by `Lib_info.requires` must correctly reflect the intended dependency set.
- For a package whose metadata indicates that it should depend on `baz` under the active conditions, calling `Lib_info.requires` and printing the result via `Dyn.list Lib_dep.to_dyn` must yield:

```ocaml
[ "baz" ]
```

Ensure that all callers and producers of library dependency lists use the moved `Dune_lang.Lib_dep` module consistently, and that `Lib_dep.to_dyn` works for values returned by `Lib_info.requires` without requiring any caller-side adaptation.