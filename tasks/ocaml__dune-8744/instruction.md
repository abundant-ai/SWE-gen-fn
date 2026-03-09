When using Dune’s package/lockdir workflow, resolving binaries via the “which” mechanism is incorrect: `Context.which` does not look up executables provided by packages built from the lock directory. This breaks workflows where a rule depends on a lockdir package and then tries to execute or locate a binary from that package.

Reproduction scenario:
1) Create a lock directory containing a package (e.g. `foo`) that installs a binary named `foo` into the package prefix.
2) In the workspace, define a rule that depends on that package (using `(deps (package foo))`) and in the action tries to locate/execute `foo`, e.g. `(run which foo)` and/or uses `%{bin:foo}`.

Actual behavior:
- The action cannot correctly locate `foo` via `which`, and `%{bin:foo}` is not reliably resolved to the executable produced in the package’s lockdir build/install prefix.
- As a result, rules that depend on locally built packages from the lock directory cannot run or resolve their installed tools.

Expected behavior:
- `Context.which` must search for executables provided by packages in the lock directory (i.e. the package build/install prefix under Dune’s package build area) so that:
  - After `(deps (package foo))`, `(run which foo)` finds the `foo` executable installed by that package.
  - `%{bin:foo}` expands to the path of the `foo` executable coming from the lockdir package installation.
- The same visibility should hold transitively: if a package `usetest` depends on package `test` which installs a `foo` binary, then building `usetest` should be able to run `foo` during its build steps.
- Installed binaries from lockdir packages should also be visible to the workspace itself, so a workspace rule using `(run %{bin:foo})` succeeds once the corresponding lockdir package is available.