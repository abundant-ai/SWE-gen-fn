PostgREST currently has no way to dump the schema cache from a running instance; dumping is only possible at startup using the CLI flag `--dump-schema`. This makes it difficult to inspect the effective schema cache in a live server without restarting it.

Add support for dumping the in-memory schema cache through the Admin API. When the Admin server is enabled, a GET request to the admin endpoint `/schema_cache` should return `200 OK` with `Content-Type: application/json` and a JSON document representing the current schema cache (the same information that would be produced by the startup `--dump-schema` output, but served over HTTP).

Example:

```bash
curl -i http://localhost:3001/schema_cache

HTTP/1.1 200 OK
Content-Type: application/json

{ ...schema cache json... }
```

If the Admin API is not enabled/configured, `/schema_cache` should not be available (i.e., it should behave like other admin endpoints when the admin server is disabled).

The output must be generated from the running instance’s current schema cache (not by re-querying or rebuilding from scratch) so that it accurately reflects what PostgREST is using for request planning and introspection at that moment.