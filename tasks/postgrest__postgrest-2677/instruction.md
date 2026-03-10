PostgREST generates inefficient SQL for JSON-bodied requests (notably RPC calls and INSERT/UPSERT flows that parse a JSON payload into records). The generated SQL currently wraps the JSON payload normalization and extraction in nested CTEs like `pgrst_payload` and `pgrst_body`, then references them via subselects (e.g., `FROM json_to_recordset((SELECT val FROM pgrst_body))`).

On PostgreSQL 12+ this pattern can prevent inlining and lead to much worse execution plans, so limits/filters do not effectively apply to the underlying work. In practice, RPC requests that should be fast become slow (e.g., calls that should complete in ~100ms taking ~2s), and write endpoints have reduced transactions-per-second.

When PostgREST receives a JSON payload (single object or array) it should still behave the same as today—accept both object and array payloads by normalizing objects into a single-element array, parse the payload into arguments/rows, and execute the target function or INSERT exactly as before—but it must generate SQL that avoids the CTE-based payload/body steps.

Update SQL generation so that JSON payload handling uses `LATERAL` instead of CTEs. Concretely:

- For RPC calls that pass JSON arguments, replace the `WITH pgrst_payload AS (...), pgrst_body AS (...)` approach with a `FROM (...) pgrst_payload, LATERAL (...) pgrst_uniform_json, LATERAL (...) pgrst_body, LATERAL <function call> ...` structure.
- Ensure the JSON normalization logic is preserved: if `json_typeof(payload) = 'array'` use it directly; otherwise wrap it with `json_build_array(payload)`.
- Ensure argument extraction preserves previous behavior for single-row argument records (e.g., for functions expecting scalar args, only the first element should be used when appropriate).
- For INSERT requests with `Prefer: return=representation`, ensure the body is still parsed through `json_to_recordset` using the same column mapping rules, including handling of nullable fields and unusual column names (e.g., names containing hyphens that require quoting).

The externally visible behavior must not change (same HTTP status codes, response bodies, and headers for RPC/read/write requests), but query plans should improve by allowing PostgreSQL to inline the payload expression, resulting in significantly better performance (as evidenced by improved cost/plan characteristics and higher TPS).