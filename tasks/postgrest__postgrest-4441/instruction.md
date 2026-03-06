When PostgREST is configured with `server-host = "!6"` (or `PGRST_SERVER_HOST='!6'`), it is documented and expected to bind only to IPv6. However, the server currently also accepts IPv4 connections in this configuration.

Reproduction:

1) Start PostgREST with `PGRST_SERVER_HOST='!6'` and the usual port (for example the default 3000).
2) Make an IPv4-only request to the HTTP endpoint (for example `curl localhost:3000/projects --ipv4 -I`).

Actual behavior:

The request succeeds and returns a normal HTTP response (e.g., `HTTP/1.1 200 OK`), indicating the server is reachable via IPv4 even though it was configured to be IPv6-only.

Expected behavior:

With `server-host` set to `!6`, PostgREST must not accept IPv4 connections. An IPv4-only request should fail to connect (connection refused / no route / cannot connect), while IPv6 requests to the same endpoint should succeed.

This should be consistent with the existing behavior of `server-host = "!4"`, where IPv6-only requests fail to connect and only IPv4 works.

Implement whatever changes are necessary so that the `!6` special value results in binding exclusively to IPv6 (and does not also bind/dual-stack on IPv4), including ensuring that any internal host/address normalization and server startup/bind logic honors the IPv6-only intent for `!6`.