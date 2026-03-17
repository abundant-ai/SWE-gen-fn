When generating a new Phoenix project using the sqlite3 Ecto adapter, the generated release behavior around database migrations is incorrect.

Currently, the generators add logic to run migrations via `Ecto.Migrator`, but it only runs migrations when the application is running inside a release. For sqlite3, the intended behavior is to automatically run migrations when the release starts, so that deployments don’t require an explicit manual `eval`/`rpc` migration step just to bring the database schema up to date.

This should be implemented in both the standard `mix phx.new` generator and the `mix phx.new --umbrella` generator when `--database sqlite3` is used:

- The generated project should include `Ecto.Migrator` integration for the repo so migrations can be executed at startup.
- Migrations should run automatically at application/release start for sqlite3 projects (not only when some additional condition is met). The generated code should still allow end users to customize or disable this behavior in production if they prefer a different migration strategy.

Example scenario: after generating a project with sqlite3 and building/running a release, starting the release should ensure all migrations under the repo’s migrations directory are applied before the application begins serving requests. In umbrella projects, the generated release startup should likewise run the migrations for the repo used by the umbrella apps.