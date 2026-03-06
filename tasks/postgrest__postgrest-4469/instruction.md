Running the Nix helper script `postgrest-test-replica` can fail locally with PostgreSQL failing to start. The failure shows up as:

```
pg_ctl: could not start server
Examine the log output.
Temporary directory kept at: ...
```

This happens because the Nix-generated temporary directory names combined with the current helper script names (e.g. `postgrest-with-postgresql-XX`) can produce a UNIX socket path that exceeds the maximum allowed length (107 characters). When that limit is exceeded, PostgreSQL cannot create/bind the socket, causing `pg_ctl` startup to fail.

The Nix-provided helper scripts that spin up Postgres for development/testing should be adjusted so that their generated paths (including temporary directory names and socket paths) reliably stay under the 107-character socket path limit. In particular, the scripts currently exposed as `postgrest-with-postgresql-XX` should be renamed to a shorter form, `postgrest-with-pg-XX`, and any existing usages/invocations in repository tooling and documentation examples should continue to work with the new names.

After the change:
- `postgrest-test-replica` should start the PostgreSQL instance successfully on a typical Linux system using Nix, without hitting socket path-length issues.
- Users should be able to run commands like `postgrest-with-pg-15 ...` (e.g., to load fixtures with `psql` or run `pgbench`) and get the same behavior as before, just with shorter script names.
- The output guidance printed by these scripts (such as how to connect with `psql` and where to tail logs) should reflect the renamed commands.