When generating a new Phoenix application with `mix phx.new --database sqlite3`, the generated application supervision tree includes an `Ecto.Migrator` child configured with a `:skip?` option that calls a generated function named `skip_migrations?/0`.

Currently, the generated `skip_migrations?/0` logic does the opposite of what the surrounding comment indicates. The code is generated like:

```elixir
defp skip_migrations?() do
  # By default, sqlite migrations are run when using a release
  System.get_env("RELEASE_NAME") != nil
end
```

In a release, `RELEASE_NAME` is set, so this returns `true`. Because `:skip?` treats `true` as “skip migrations”, migrations are skipped in releases, which contradicts the intended default described by the comment (“migrations are run when using a release”).

Update the generated code for SQLite so that the default behavior matches the intent: when running in a release (i.e., `RELEASE_NAME` is present), `skip_migrations?/0` should evaluate such that migrations are not skipped by default. In non-release environments, it should still behave sensibly (local/dev should not accidentally run release-only migration behavior).

After the change, generating a new app with `--database sqlite3` should produce consistent, correct wording and behavior: migrations should run by default in releases instead of being skipped due to an inverted `skip_migrations?/0` condition.