When a PostgREST endpoint queries a PostgreSQL view that has infinite recursion, PostgreSQL raises error code `42P17` with a message like `infinite recursion detected in rules for relation "view_projects"`. PostgREST currently converts this database error into an HTTP `400 Bad Request` response, even though the request is valid and the failure is a server-side database/schema problem.

Reproduction example:

```sql
create view test.view_projects as
select * from test.projects;

create or replace view test.view_projects as
select * from test.view_projects;
```

Request:

```bash
curl -i http://localhost:3000/view_projects
```

Current behavior returns `HTTP/1.1 400 Bad Request` with a JSON error body containing `"code":"42P17"` and message `"infinite recursion detected in rules for relation \"view_projects\""`.

Expected behavior: for PostgreSQL error code `42P17`, PostgREST should respond with `HTTP 500 Internal Server Error` (while still returning the same structured JSON error payload including the `code` and `message`). Any internal mapping/function that converts PostgreSQL SQLSTATE error codes into HTTP status codes must treat `42P17` as a server error rather than a client error, so that querying a recursively-defined view no longer yields a 400.