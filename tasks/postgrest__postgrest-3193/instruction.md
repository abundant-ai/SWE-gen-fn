PostgREST currently supports `--dump-config` to print the effective configuration (after applying env vars, config files, and in-database config), but this only works at process start and cannot be used to inspect the configuration of an already running instance.

Add support for dumping the *live* effective configuration via the Admin API. When the admin server is enabled, an HTTP GET request to the admin endpoint `/config` must return `200 OK` with `Content-Type: text/plain` and a body formatted like the existing `--dump-config` output. The output must reflect the configuration currently applied by the running instance, including values coming from environment variables, config files, and in-database configuration.

For example, calling:

```bash
curl localhost:3001/config
```

should respond with text lines like:

```
db-aggregates-enabled = false
db-anon-role = "postgrest_test_anonymous"
...
admin-server-port = ""
```

The endpoint should be available on the admin server (the same interface used for other admin endpoints like health checks) and should not require restarting PostgREST. The formatting and keys should match the `--dump-config` format so that operators can use it interchangeably to diagnose the running configuration.