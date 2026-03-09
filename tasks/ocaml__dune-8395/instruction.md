The findlib integration currently relies on a Lib_config field named instrument_with, but this field should no longer exist. Code that constructs or consumes Lib_config.t must be updated so that findlib creation and package resolution continue to work without any concept of instrument_with.

In particular, it should be possible to construct a Lib_config.t record containing fields such as has_native, ext_lib, ext_obj, os_type, natdynlink_supported, ext_dll, stdlib_dir, ccomp_type, ocaml_version_string, and ocaml_version, and then pass it to Findlib.create without compile errors or behavioral regressions.

After removing instrument_with from Lib_config.t, the following behaviors must still hold:

- Resolving a package via Findlib.find and then inspecting Lib_info.archives returns the same archive lists as before (e.g., libraries may have a byte archive like "/qux/qux.cma" and an empty native archive list).
- Meta requires handling remains correct: for a META snippet where requires = "bar" and requires(ppx_driver) = "baz", the effective dependencies exposed through Lib_info.requires for the corresponding resolved library must include "baz" (and not incorrectly include the non-matching rule).

If any callers previously used instrument_with to influence resolution or metadata processing, that behavior must be preserved through other existing mechanisms, but Lib_config must no longer expose instrument_with and all compilation and runtime behavior around findlib package resolution must remain consistent.