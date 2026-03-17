PostgREST currently continues operating (or repeatedly retries connecting) even when the connected PostgreSQL server is on an unsupported major version, and the project still implicitly supports very old PostgreSQL versions (e.g., 9.5) despite upstream EOL. This leads to two related problems:

1) Unsupported PostgreSQL versions are not rejected early and clearly. When PostgREST is pointed at a PostgreSQL server whose version is below the minimum supported version (e.g., PostgreSQL 7.4, or 9.5 once support is dropped), the server should fail fast during startup after it can connect, instead of continuing with “Retrying the connection” style behavior. The error presented to the user should clearly state that the PostgreSQL version is unsupported and what the minimum supported version is.

2) The internal PostgreSQL version detection and version gating must align with the new minimum supported version. PostgREST determines the server version via `queryPgVersion` and stores it in app state, and some behaviors are conditioned on `PgVersion` comparisons (for example, error message differences around PostgreSQL 12.1 are already handled via `PgVersion` constants like `pgVersion112` and `pgVersion121`). After dropping PostgreSQL 9.5 support, any code paths that would allow PostgREST to proceed on 9.5 must be removed or guarded so that initialization halts with the unsupported-version error.

To reproduce the problem:
- Configure PostgREST to connect to a PostgreSQL instance running a version below the supported minimum (for example, PostgreSQL 7.4; or PostgreSQL 9.5 after raising the minimum).
- Start PostgREST.

Expected behavior:
- PostgREST connects, queries the PostgreSQL version, detects it is below the supported minimum, and terminates startup with a clear fatal error indicating the connected PostgreSQL version is unsupported and stating the minimum supported PostgreSQL version.
- It should not enter an indefinite connection retry loop once it has successfully connected but determined the version is unsupported.

Actual behavior:
- PostgREST does not reliably quit on unsupported PostgreSQL versions and can keep retrying the connection instead of reporting a definitive unsupported-version failure.

Implement the missing behavior by ensuring the startup/initialization flow uses the value returned by `queryPgVersion` (and the `PgVersion` comparison helpers/constants) to enforce a minimum PostgreSQL version, and produces a clear user-facing error when the version is too old.