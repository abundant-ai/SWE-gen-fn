Calling PostgREST RPC endpoints with parameters declared as fixed-length PostgreSQL types like `character(n)` (aka `char(n)`) or `bit(n)` incorrectly ignores the declared length and treats the parameter as if it were length 1. This causes valid inputs (e.g., 4-character PINs) to fail with a PostgreSQL error.

For example, given a function like:

```sql
create or replace function functions.register_user(username varchar(80), pin char(4))
returns void as $$
  insert into api.user values(DEFAULT, username, pin);
$$ language sql;
```

Sending a request that passes `pin` as "0000" should succeed, but currently PostgREST returns an error like:

```json
{"details":null,"code":"22001","message":"value too long for type character(1)","hint":null}
```

The same issue applies to `bit(n)` parameters, where values longer than 1 are incorrectly rejected as if the type were `bit(1)`.

PostgREST should correctly preserve and apply the full declared length for parameters of type `character(n)` and `bit(n)` when building and casting RPC parameters (whether parameters are supplied via query string or JSON request body). After the fix, RPC calls that pass values whose length matches the declared `n` must succeed (e.g., `char(4)` accepts 4 characters; `bit(4)` accepts 4 bits), and the incorrect `character(1)`/`bit(1)` length behavior must no longer occur.