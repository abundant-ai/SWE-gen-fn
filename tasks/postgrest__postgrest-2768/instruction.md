PostgREST v11 has multiple regressions affecting database privilege assumptions and error handling.

1) Incorrect error behavior/message when inserting into tables with GENERATED ALWAYS columns while using `Prefer: missing=default`.

Given a table with a generated stored column, e.g.

```sql
create table foo (
  a text,
  b text GENERATED ALWAYS AS (
      case WHEN a = 'telegram' THEN 'im'
           WHEN a = 'proton' THEN 'email'
           WHEN a = 'infinity' THEN 'idea'
           ELSE 'bad idea'
      end) stored
);
```

When issuing an insert request that includes `Prefer: missing=default` and specifies both columns in `?columns=...`, for example sending JSON rows where one row omits `b` and another provides `b`, PostgREST currently produces a misleading PostgreSQL error like:

```json
{
  "code": "42703",
  "details": null,
  "hint": "There is a column named \"a\" in table \"foo\", but it cannot be referenced from this part of the query.",
  "message": "column \"a\" does not exist"
}
```

This happens because PostgREST tries to apply “missing=default” logic in a way that references other columns (like `a`) while building defaults for `b`, which breaks for generated columns.

Expected behavior: PostgREST must not attempt to apply defaults for `GENERATED ALWAYS` columns when `Prefer: missing=default` is present. If a client attempts to insert a non-DEFAULT value into a generated column, PostgreSQL should raise the correct error and PostgREST should surface it, e.g.:

```json
{
  "code": "428C9",
  "details": "Column \"b\" is a generated column.",
  "hint": null,
  "message": "cannot insert a non-DEFAULT value into column \"b\""
}
```

2) v11 schema cache load repeatedly fails with “permission denied for schema …” when using the recommended authenticator + anon role setup.

With a common configuration:

```sql
create schema api;

create role web_anon nologin;
grant usage on schema api to web_anon;

create role authenticator noinherit login password 'mysecretpassword';
grant web_anon to authenticator;
```

and PostgREST configured with `db-schemas = "api"` and `db-anon-role = "web_anon"`, PostgREST v11 connects successfully but then loops with schema cache load errors:

```json
{"code":"42501","details":null,"hint":null,"message":"permission denied for schema api"}
```

Current behavior incorrectly requires granting `USAGE` on the API schema directly to the authenticator role to start.

Expected behavior: PostgREST should be able to start and load the schema cache without granting schema usage to the authenticator role, as long as the anon role (or effective role used for schema discovery) has the required privileges. The repeated error loop should not occur under the documented role setup.

3) Nix-based `postgrest-with-postgresql-*` environments default to a superuser connection role, breaking privilege assumptions.

In the Nix helper environment, connecting via `postgrest-with-postgresql-15 psql` currently yields a `current_user` that is a superuser (e.g. `is_superuser = on`). This undermines tests and real-world validation that the authenticator role is unprivileged.

Expected behavior: the default connection role in these environments must not be a PostgreSQL superuser. There should be an SQL-accessible check (exposed via an RPC endpoint) such that calling `GET /rpc/is_superuser` returns `false` when run under the normal authenticator connection.

Fix these issues so that:
- `Prefer: missing=default` does not trigger default application for generated columns, avoiding misleading “column does not exist” errors and allowing PostgreSQL to raise the correct generated-column insertion error.
- PostgREST v11 no longer requires schema usage on the target schema to be granted directly to the authenticator role for schema cache loading when role inheritance is configured as documented.
- The Nix `postgrest-with-postgresql-*` setup no longer uses a superuser as the default connection role, and `/rpc/is_superuser` returns `false` under the default test/authenticator role.