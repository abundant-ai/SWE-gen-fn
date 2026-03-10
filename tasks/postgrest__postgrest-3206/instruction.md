When querying a view or function that contains a scalar subquery which unexpectedly returns multiple rows, PostgreSQL raises SQLSTATE `21000` (`cardinality_violation`) with an error like `more than one row returned by a subquery used as an expression`. PostgREST currently maps this to `400 Bad Request` when the endpoint is invoked over HTTP (for example, `GET /bad_subquery`), but this is incorrect because the client request is valid and the failure is an internal server-side query error.

Update PostgREST’s PostgreSQL error-to-HTTP mapping so that `cardinality_violation` (SQLSTATE `21000`) is returned as `500 Internal Server Error`.

At the same time, PostgREST must preserve existing behavior for the `pg-safeupdate` extension: pg-safeupdate can also surface errors using the `cardinality_violation` code to signal a client-side “unsafe update” situation, and in that specific pg-safeupdate case the response should remain `400 Bad Request`. The distinction must be made based on the pg-safeupdate error message content (i.e., only treat `21000` as 400 when it is clearly the pg-safeupdate “safe update” rejection; otherwise treat it as 500).

Reproduction example:

1) Create a view with a bad scalar subquery:
```sql
create view bad_subquery as
select * from projects where id = (select id from projects);
```
2) Querying it in psql yields SQLSTATE `21000` with message `more than one row returned by a subquery used as an expression`.
3) Calling it through PostgREST (e.g., `curl -i http://localhost:3000/bad_subquery`) currently returns `HTTP/1.1 400 Bad Request`, but it should return `HTTP/1.1 500 Internal Server Error`.

Expected behavior: `GET /bad_subquery` responds with status 500.
Actual behavior: responds with status 400.