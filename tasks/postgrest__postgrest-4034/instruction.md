A CI load test is needed to continuously validate performance of JWT decoding when many distinct JWTs are used (to exercise the JWT cache and its purge behavior). Today this benchmark is run manually and is too slow/repetitive, and there is no automated signal in CI when JWT-cache performance regresses.

Implement a loadtest command (used by CI) that:

- Generates an HTTP targets file containing many requests to a JWT-protected endpoint (e.g., `GET http://localhost:3000/authors_only`) where each request uses a different `Authorization: Bearer <JWT>` header. The generated file should be large (on the order of 50,000 targets) and generation must be fast enough for CI.
- Runs `vegeta` against that generated targets file and prints a summary suitable for CI logs/summary output.

The load test should be able to run against different PostgREST versions/commits (e.g., “v12.2.9” vs “HEAD”) and demonstrate that older versions may fail to finish all generated targets within the configured duration while newer versions complete them with substantially higher throughput.

Additionally, JWT validation currently uses a hardcoded 30-second clock skew. This makes time-based JWT tests/loadtests slow because CI would need to wait ~30 seconds before requests become valid/invalid as intended. Add a new configuration option `jwt-skew` that controls the allowed clock skew used during JWT validation. It must be possible to set it to a small value (e.g., 1 second) so load tests can start quickly.

Expected behavior:

- The loadtest runner can generate a targets file containing repeated `GET /authors_only` requests, each with a distinct JWT, without taking an excessive amount of time.
- Running the load test executes all/most of the generated targets within the configured attack duration and reports requests, throughput, latency, success ratio, and status codes.
- PostgREST accepts a `jwt-skew` setting and uses it when validating JWT `nbf`/`iat`/`exp` time-based claims, instead of an unconfigurable fixed 30 seconds.
- Setting `jwt-skew=1` (or similar) reduces the waiting time needed for time-based JWT scenarios and enables the CI loadtest to run faster.

Actual behavior to fix:

- There is no CI-integrated load test that uses many different JWTs; performance regressions in JWT decoding/cache behavior can slip in unnoticed.
- JWT clock skew is fixed at 30 seconds, making fast-running time-based JWT loadtests impractical.