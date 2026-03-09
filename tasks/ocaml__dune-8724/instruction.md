Converting opam package build/install commands into dune lockfile actions mishandles several opam variables.

1) Global opam variables are not implemented consistently in the generated dune actions. For example, an opam build command like:

  build: [ ["echo" jobs] ]

is translated into a dune lockfile action that references %{jobs}, but when building the package dune errors with:

  Error: Unknown variable %{jobs}

Dune should recognize and expand the global variables used by opam commands, at minimum including: jobs, make, user, and group. In particular, %{jobs} must be defined (expected to be "1"). %{make} should resolve to the build tool used for “make”. %{group} should resolve to the current user’s group name. (The user value is platform dependent; it should not crash or be unimplemented.)

2) System/OS-related opam variables are translated inconsistently, mixing generic and package-scoped forms. Given an opam file that echoes:

  arch
  os
  os-distribution
  os-family
  os-version

these should translate to dune variables that expand to the same values as `opam var` reports for those names. The translation currently produces a mix such as %{arch}, %{pkg-self:os}, %{os_distribution}, %{os_family}, %{os_version}, and building the package does not yield output matching opam’s values. All these variables should expand correctly at build time and match opam’s semantics.

3) Package-variable macro expansion is incorrect for opam’s package-scoped variables (e.g. foo:version, foo:installed, foo:enable, etc.). When converting opam commands that use these variables in filters or command arguments, the generated dune expressions should reference the correct package variable namespace and expand reliably. Currently, some package variables are expanded as the wrong kind of variable (e.g. treated like local variables or mis-scoped), leading to incorrect lockfile output or failures during conversion/build.

4) Unsupported opam variables should be rejected with clear, consistent error messages during conversion. When an opam build command references any of these variables:

  opam-version
  root
  _:hash
  _:build-id
  misc
  _:misc

conversion must fail and report an error of the form:

  Error: Variable "<name>" occuring in opam package "<pkg>" is not supported.

The variable name shown for prefixed forms like "_:hash" must be reported as "hash" (and similarly for "_:build-id" and "_:misc"). Additionally, “misc” must not be treated as a supported switch/global variable.

Overall, update the opam-to-dune conversion and variable expansion so that: (a) supported opam variables (global, OS, switch-like, and package-scoped) are translated into dune variables that are known and correctly expanded at build time, and (b) explicitly unsupported variables fail early with the exact diagnostic format shown above.