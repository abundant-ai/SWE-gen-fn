Building the aarch64 (ARM) Linux release artifact currently produces a binary that does not run on Ubuntu 18.04 because it is linked against a GLIBC version newer than 2.27. Users attempting to execute the ARM release binary on Ubuntu 18.04 encounter a runtime loader error indicating the required GLIBC version is not available (e.g., an error of the form: "version `GLIBC_2.xx` not found"), even though Ubuntu 18.04 should be a supported target for the distributed Ubuntu aarch64 tarball.

This regression is caused by the build requiring a newer GHC toolchain: enabling/using the GHC language feature OverloadedRecordDot forces the compiler baseline to GHC >= 9.2, which in turn typically requires a newer glibc than Ubuntu 18.04 provides. As a result, the produced ARM binary becomes incompatible with older Ubuntu LTS environments.

The build must be adjusted so that the project can be compiled with GHC 9.0.2 (the latest GHC available in Ubuntu’s packages for the relevant baseline) and must not rely on OverloadedRecordDot. After the change:

- The codebase should compile successfully with GHC 9.0.2.
- The produced Ubuntu aarch64 release binary should run on Ubuntu 18.04 without requiring GLIBC > 2.27.
- CI should fail if the code accidentally starts requiring a newer GHC than 9.0.2 (so future changes don’t reintroduce the newer-glibc dependency).

Ensure any record-field access previously written using OverloadedRecordDot syntax is rewritten to a form compatible with GHC 9.0.2, without changing the server’s runtime behavior or HTTP responses.