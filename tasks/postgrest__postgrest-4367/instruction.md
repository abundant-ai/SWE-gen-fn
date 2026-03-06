PostgREST’s behavior during initial startup is inconsistent with its behavior during later schema-cache reloads.

When PostgREST is starting up and the schema cache has not finished loading yet (or a schema-cache query fails transiently and is retried), incoming HTTP requests are immediately rejected with a 503 response. The client receives a JSON error body like:

```json
{"code":"PGRST002","details":null,"hint":null,"message":"Could not query the database for the schema cache. Retrying."}
```

Two problems need to be fixed:

1) On startup, requests should wait for the schema cache to become ready (similar to how requests are handled during an explicit schema-cache reload). Instead of immediately returning a 503 during the initial schema-cache load/retry window, requests should block until the schema cache is available and then proceed normally.

2) When a request does result in a PGRST002 503 response, the JSON error message body is not being logged. PostgREST should log the JSON message associated with the PGRST002 error so operators can see the actual error payload that clients receive.

Reproduction scenario: start PostgREST (especially against a database where schema-cache querying can take noticeable time) and issue requests immediately as the service is coming up. Currently the requests can receive repeated 503 responses with code PGRST002 until the schema cache finishes querying. Expected behavior is that those requests wait until the schema cache is ready and then return the normal endpoint response (e.g., 200 for a valid route). Additionally, when PGRST002 does occur, its JSON error payload should appear in logs rather than only the access log line with status 503.