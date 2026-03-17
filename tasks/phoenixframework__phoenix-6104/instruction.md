When generating a new Phoenix project via `Mix.Tasks.Phx.New.run/1`, the installer should support redirecting its cached build/artifact directory via an environment variable named `PHX_NEW_CACHE_DIR`.

Currently, cached builds always use the default cache location, which makes it difficult to run the installer in restricted environments (such as CI containers or read-only home directories) or to share a cache across runs in a custom location. Setting `PHX_NEW_CACHE_DIR` has no effect.

Update the Phoenix installer so that when `PHX_NEW_CACHE_DIR` is set to a non-empty string, all cache reads/writes performed during `phx.new` project generation use that directory instead of the default. This should apply consistently for the full installer flow (including any operations that prepare or reuse cached build output used for creating the project).

Example:

```elixir
System.put_env("PHX_NEW_CACHE_DIR", "/tmp/phx-new-cache")
Mix.Tasks.Phx.New.run(["my_app"])
```

Expected behavior: the installer uses `/tmp/phx-new-cache` for its cached builds (creating the directory if needed), and project generation succeeds while reusing the cache on subsequent runs.

Actual behavior: the installer ignores `PHX_NEW_CACHE_DIR` and continues using its default cache directory.

If `PHX_NEW_CACHE_DIR` is unset or set to an empty value, the existing default cache directory behavior should remain unchanged.