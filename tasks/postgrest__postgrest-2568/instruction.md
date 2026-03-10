When calling an RPC endpoint that returns a set of rows (SETOF a table), embedding a many-to-many related resource fails if the top-level select does not explicitly include the base row fields.

Given a schema like:

- A base table `test.yards(id bigint primary key)`
- A related table `test.groups(name text primary key)`
- A junction table `test.group_yard(id bigint not null, group_id text not null references test.groups(name), yard_id bigint not null references test.yards(id), primary key (id, group_id, yard_id))`
- An RPC `test.get_yards()` defined as `RETURNS SETOF test.yards` and returning `select * from test.yards;`

Calling:

```bash
curl "http://localhost:3000/rpc/get_yards?select=groups(*)"
```

should succeed and return the yards with an embedded `groups` array (possibly empty), but it currently fails with a Postgres error like:

```json
{"code":"42703","details":null,"hint":null,"message":"column get_yards.name does not exist"}
```

A workaround currently is:

```bash
curl "http://localhost:3000/rpc/get_yards?select=*,groups(*)"
```

which succeeds (returns `[]` for an empty dataset).

The bug is that embedding a many-to-many relationship from an RPC result set incorrectly generates a query that references columns as if they were on the RPC result alias (e.g., `get_yards.name`) when they actually belong to the embedded table (e.g., `groups.name`) or should be joined through the junction table using the correct keys. This regression does not occur on v9.0.0/v9.0.1 but occurs on v10.

Fix RPC embedding so that `GET /rpc/<proc>?select=<embed>(*)` works for many-to-many relationships even when the base selection omits `*`. The embedding should not require `select=*` to be present, and it must not generate invalid column references on the RPC source alias. The request should return HTTP 200 with a valid JSON response instead of a 42703 error.