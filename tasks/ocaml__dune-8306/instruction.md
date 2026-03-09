Dune’s file copying implementation can produce corrupted/incomplete output when the optimized sendfile-based copy path fails and Dune falls back to its portable copy implementation. This shows up in real builds (e.g., during `opam upgrade`) on Linux with OCaml 5 and Dune 3.9.2, where packages fail to build and/or installed artifacts are incorrect.

When copying/installing files, Dune may attempt to use `sendfile`. If `sendfile` fails (for example returning `EINVAL`), Dune must fall back to a portable copy implementation and still produce an identical destination file. Currently, when this fallback is taken for larger files, the destination can end up missing data (the copied file differs from the source). This indicates buffered output was not fully written before or during the fallback copy path.

Reproduction scenario:
- Create a project that copies and installs a small file and a large file (e.g., a ~100KB+ file of zeros).
- Force `sendfile` to fail (e.g., by running on a system/kernel/filesystem combination where `sendfile` returns `EINVAL`, or by injecting such a failure when tracing system calls).
- Run `dune build @install`.
- Compare the source large file with the produced/copied output in the build directory.

Expected behavior:
- If `sendfile` fails, Dune reliably falls back to the portable copy implementation.
- The copied output file is byte-for-byte identical to the source file for both small and large files.
- Builds and `opam upgrade` do not fail due to corrupted installed/copied artifacts.

Actual behavior:
- After `sendfile` fails and the fallback path is used, the copied large file can be incomplete/corrupted (byte comparison fails).

Fix requirement:
- Ensure that when Dune uses an `out_channel` (or equivalent buffered output abstraction) in the sendfile fallback path, any buffered data is properly flushed so the final file contents are complete and correct. The fallback copy must not leave partially written buffered data that causes truncation or mismatched contents.