PostgREST’s admin health checking endpoints behave incorrectly when the main HTTP server is listening on a Unix domain socket. The admin server exposes a readiness-style endpoint intended for load balancers/orchestrators, but this endpoint currently does not verify that the main app socket is actually accepting connections. As a result, the admin endpoint can report a healthy/ready state even when the main server socket has been removed or is otherwise unreachable.

Update the admin endpoints so that readiness is tied to the availability of the main application socket:

- The admin server should expose a `GET /ready` endpoint (replacing the previous `GET /health`).
- `GET /ready` must attempt to connect to the main PostgREST application endpoint (including when it is configured to listen on a Unix domain socket). If the connection cannot be established (for example, the Unix socket file has been deleted while the process is still running), `/ready` should return a non-2xx response indicating the service is not ready.
- The admin server should also expose a `GET /live` endpoint. This endpoint is a liveness probe and should return success as long as the PostgREST process is running (it should not depend on being able to connect to the main application socket).

Reproduction scenario to support:

1) Start PostgREST configured to serve HTTP over a Unix domain socket.
2) Confirm the admin server endpoints are reachable.
3) Remove the Unix socket file used by the main application server while leaving the PostgREST process running.
4) Calling `GET /ready` should fail (service not ready) because the admin server cannot connect to the main app socket.
5) Calling `GET /live` should still succeed because the process is alive.

Expected behavior: `/ready` accurately reflects whether clients can connect to the main app endpoint; `/live` reflects only process liveness. Actual behavior (current): readiness/health reporting can succeed even when the main app socket is unavailable.