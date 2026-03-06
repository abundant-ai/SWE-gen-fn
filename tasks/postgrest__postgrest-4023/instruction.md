`postgrest-loadtest-report` fails when run locally after executing `postgrest-loadtest`, and the loadtesting tooling also needs a new mode to run requests with unique JWTs to measure JWT decoding + cache behavior.

Currently, a typical local workflow is:

```bash
postgrest-loadtest
postgrest-loadtest-report > report.md
```

However, `postgrest-loadtest-report` crashes with a Python traceback during Markdown generation (it fails inside `pandas.DataFrame.to_markdown()`/`tabulate`), so users cannot generate a local report from the produced loadtest output.

Additionally, the loadtest runner needs to support running a JWT-focused scenario where each request uses a different `Authorization: Bearer <JWT>` value (similar to a “different JWT per request” benchmark). The goal is to run this both locally and in CI to evaluate the performance impact of JWT decoding and the JWT cache.

Implement support for an optional `-k/--kind` parameter in both `postgrest-loadtest` and `postgrest-loadtest-against` with at least these behaviors:

- Default kind remains `mixed` (existing behavior preserved).
- A new kind `jwt` runs a loadtest that repeatedly calls the protected endpoint `/authors_only` while sending a different JWT in the `Authorization` header for each request.

For the `jwt` kind, the loadtest must dynamically generate a vegeta targets input with repeated blocks like:

```http
GET http://<host>:<port>/authors_only
Authorization: Bearer <jwt>

GET http://<host>:<port>/authors_only
Authorization: Bearer <another-jwt>
```

Then execute vegeta using that generated targets data in a way that works reliably in automated environments (CI) and locally.

Expected behavior:

- `postgrest-loadtest -k mixed` and `postgrest-loadtest-against -k mixed` behave exactly as before.
- `postgrest-loadtest -k jwt` and `postgrest-loadtest-against -k jwt` perform a load test where a large number of requests are sent with unique JWTs.
- After running `postgrest-loadtest` (either kind), running `postgrest-loadtest-report` must successfully produce Markdown output to stdout without throwing exceptions.

The change should be robust enough that the “Summary” output produced in CI includes results from the JWT-focused loadtest mode, and local runs should no longer error when generating the report.