Building OCaml projects that compile C++ stubs against the OCaml runtime headers can fail or regress silently when OCaml headers are no longer C++-compatible. This needs a robust compatibility check in the test suite that compiles a C++ translation unit including OCaml headers and exercises a minimal runtime interaction, and it must work on both GCC (e.g., GCC 13) and MSVC.

Problem: there is currently no reliable, cross-platform check that OCaml’s public C API headers remain usable from C++. When C++ compilation breaks (for example due to C++-invalid constructs or toolchain-specific diagnostics), the failure mode is either not caught by CI or is too noisy/unstable to act on consistently. Some diagnostics are unavoidable in C++ mode (e.g., flexible array members, which are only a C++ extension in some compilers), so the check must be able to ignore a known set of diagnostics while still failing on real regressions.

Expected behavior:
- When a C++ compiler is available, the test suite should compile a C++ source file that includes OCaml headers (at minimum the headers needed for allocation, GC roots, and threads) and defines an OCaml C stub function `test_cxx` callable from OCaml.
- The C++ stub should perform a simple runtime action that validates thread/runtime API correctness in C++ mode: it should call `caml_release_runtime_system()`, do a trivial libc call (e.g., `time(NULL)`), then call `caml_acquire_runtime_system()`, and finally return an OCaml string (e.g., "ok\n") using `caml_copy_string`, with GC root management via `CAMLparam`/`CAMLlocal`/`CAMLreturn`.
- Running the resulting OCaml program must print exactly `ok` followed by a newline.

Toolchain/driver requirements:
- The check must only run when a usable C++ compiler is detected and the test harness is enabled.
- The build/test environment must correctly invoke the C++ compiler:
  - On MSVC, invoking `cl.exe` must compile as C++ based on the `.cpp` extension.
  - On GCC-like toolchains, the driver must compile as C++ (e.g., with `-x c++` when necessary).
  - The detection should also ensure the GCC default language mode is at least C++11 (or otherwise ensure compilation uses C++11-or-newer), since older defaults can cause spurious failures.

Diagnostics handling:
- Compiler diagnostics for the C++ compilation step should be captured in SARIF so that CI can reliably parse, classify, and filter them.
- The SARIF handling must allow ignoring a known set of unavoidable diagnostics (e.g., those triggered by flexible array members in headers) while still failing the test if any other warnings/errors occur.
- The test output/logging should clearly indicate where the SARIF report was written so developers can replay or inspect it locally.

In short: implement a C++ API compatibility test that compiles and links a small C++ stub using `caml_release_runtime_system()` / `caml_acquire_runtime_system()` and returns an OCaml string, and make the infrastructure robust across GCC and MSVC by adding C++ compiler detection and SARIF-based diagnostics parsing/filtering so that real C++ compatibility regressions are caught without flakiness from known unavoidable diagnostics.