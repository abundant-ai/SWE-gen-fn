When PostgREST reloads the schema cache (on startup or after a reload signal), it can become very slow or even fail when PostgreSQL catalog tables such as `pg_depend` are bloated. In these cases users observe schema cache queries taking several seconds and sometimes failing due to `statement_timeout`. Separately, after a reload, subsequent metadata-heavy requests (for example retrieving the API root/OpenAPI description) can trigger long periods of high CPU usage, and clients may see truncated/partial responses or timeouts until the expensive metadata processing finishes.

The problem is that operators currently have little visibility into what the schema cache loader is doing and how expensive each part is, making it hard to diagnose whether the slowdown is coming from specific catalog queries, cache size, or other factors.

Add schema cache statistics logging to stderr so that every schema cache load/reload emits useful timing and size information. The logging should make it possible to correlate “slow reloads” with specific schema cache steps and understand how large the resulting cache is.

Expected behavior:
- On schema cache load/reload, PostgREST writes a concise stats summary to stderr.
- The stats include at least: total schema cache build time, and a breakdown of timings for major schema cache queries/steps (e.g., the table/relationship introspection that can be impacted by `pg_depend`).
- The stats include size/counter information that helps understand cache complexity (for example counts of discovered tables/views, relationships, functions/routines, or other schema entities that are part of the cache).
- Logging should occur reliably both at initial startup and on subsequent schema cache reloads.
- The logging must not change the HTTP responses, and must not cause schema cache loading to fail when it previously succeeded.

Reproduction scenario to validate:
- Run PostgREST against a database where catalog tables (notably `pg_depend`) are large/bloated so schema introspection is slow.
- Trigger a schema cache reload (restart PostgREST or use the reload notification mechanism).
- Verify that stderr contains the schema cache stats output for each reload, and that the output reflects the increased execution time (i.e., shows slow timings rather than remaining empty/silent).

This task is complete when operators can look at stderr logs and immediately see schema cache timing/counter stats for every reload, allowing diagnosis of slow or failing schema cache reloads related to catalog bloat and large schemas.