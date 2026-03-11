`mix phx.new` currently allows project names that contain uppercase letters (for example `mix phx.new exAppName`). The generator proceeds, but the created project later fails when building a release, because Mix rejects the release name derived from the app name.

Reproduction:

```sh
mix phx.new exAppName
cd exAppName
mix phx.gen.release --docker
docker build .
```

This eventually fails during `mix release` with an error like:

```
** (Mix) Invalid release name. A release name must start with a lowercase ASCII letter, followed by lowercase ASCII letters, numbers, or underscores, got: :exAppName
```

Expected behavior: `Mix.Tasks.Phx.New.run/1` should reject invalid application names up front, using the same validation rules as `mix new`. In particular, when the inferred application name contains uppercase letters, it should fail immediately with a `Mix` error and a message like:

```
** (Mix) Application name must start with a letter and have only lowercase letters, numbers and underscore, got: "exAppName". The application name is inferred from the path, if you'd like to explicitly name the application then use the `--app APP` option.
```

The validation used by `mix phx.new` should align with the rules used by `mix new` for application naming (lowercase ASCII letter start; only lowercase ASCII letters, numbers, underscores thereafter), so that generating a Phoenix project cannot produce an app/release name that will later be rejected by `mix release`.