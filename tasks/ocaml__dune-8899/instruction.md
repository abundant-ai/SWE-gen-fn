When generating a package build plan (lockfile) for a package that depends on "dune", the solver should implicitly add a constraint that pins the "dune" dependency to the version of the dune executable currently being used to generate the plan. This implicit constraint should apply even if the user’s package metadata already contains a broader constraint on dune.

Currently, generating a plan can select a dune version that is inconsistent with the dune version used to compute the plan, which can lead to plans that can’t be reliably built by the same dune.

Expected behavior:
- If the current dune version is 3.11.0, then solving a package should behave as if the dependency on "dune" included an additional constraint requiring dune to be exactly 3.11 (i.e., compatible with the currently running dune version).
- If the user specifies a dune constraint that conflicts with this implicit pin (for example, the package declares it depends on "dune" with a maximum version <= 2.0.0), solving must fail with an error indicating it cannot satisfy dependencies because dune is fixed to the current dune version.
- If the user specifies a dune constraint that allows the current dune version (for example, <= 4.0.0), solving should succeed and select the dune package matching the current dune (e.g., dune.3.11.0).

Reproduction sketch:
1) Create a package repository that contains dune version 3.11.0.
2) Create a package foo that depends on "dune" with a constraint like {<= "2.0.0"} and attempt to solve/build the lockfile plan: it should fail due to the implicit requirement for dune to match the running dune version.
3) Change foo’s constraint to {<= "4.0.0"} and solve again: it should succeed and select dune.3.11.0.

Implement the implicit constraint injection in the part of the code responsible for constructing the dependency set/build plan for solving, so that the solver sees the dune dependency as pinned to the current dune version by default.