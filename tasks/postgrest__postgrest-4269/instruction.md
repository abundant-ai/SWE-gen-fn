PostgREST currently supports readiness checking via the admin server HTTP endpoint `/ready`, but this is inconvenient in minimal container images where only the `postgrest` binary is available. Users want to perform a healthcheck (e.g., in Docker Compose) without installing extra tools like `curl`.

Implement a new command-line flag `--ready` that can be executed as a standalone PostgREST invocation to determine whether an already-running PostgREST instance is ready. This flag must behave like the admin server `/ready` endpoint:

- When invoked, `postgrest --ready` should attempt to reach the running PostgREST admin server and perform the same readiness check as `GET /ready`.
- It must exit with status code `0` when PostgREST is ready to serve requests.
- It must exit with status code `1` when PostgREST is not ready (for example, while the schema cache is still loading), or when the readiness check cannot be performed successfully.

The flag should work with the same configuration sources as the normal server process (config file and/or environment variables), including honoring the configured admin server host and port (or defaults derived from the normal server host combined with the configured admin port).

The behavior must be suitable for container healthchecks: it should run quickly, print only what is necessary for CLI usage, and terminate after performing the check rather than starting a server.

(If a `--live` flag is introduced alongside `--ready`, it should analogously mirror the admin server `/live` behavior, but `--ready` is the required functionality.)