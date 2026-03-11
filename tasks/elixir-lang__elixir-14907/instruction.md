On Erlang/OTP 28, Regex structs embedded in configuration can no longer be reliably stored and later read back as valid configuration terms for releases. This shows up when generating a release in a dev environment for a newly generated Phoenix project: running `mix release` fails while `MIX_ENV=prod mix release` succeeds.

The failure happens during release assembly when Mix reads runtime configuration and validates that all configuration values are serializable terms. A typical error is:

```
** (Mix) Could not read configuration file. It has invalid configuration terms such as functions, references, and pids.
...
Key: MyAppWeb.Endpoint
Value: [..., live_reload: [web_console_logger: true, patterns: [~r/...$/, ...]]]
```

The root problem is that on OTP 28 the internal representation of regex patterns is not portable/serializable in the same way as before, so Regex structs placed into configuration (for example, Phoenix live reload `patterns: [~r/.../]`) can be rejected as invalid configuration terms during `mix release`.

Elixir needs to support an “exported” regex representation that can be safely stored in configuration and shared across nodes. `Regex.compile!/2` already supports an `:export` option, but there is currently no literal modifier to express it, and regex literals compiled without export are not suitable for config serialization on OTP 28.

Implement support for a new regex literal modifier `E` such that a regex like `~r/foo/E` behaves the same as `Regex.compile!("foo", [:export])`. The exported regex must preserve normal regex behavior for matching and helpers, including:

- `Regex.match?(~r/foo/E, "foo")` returns `true`, while `Regex.match?(~r/foo/E, "Foo")` returns `false`.
- `Regex.run(~r/c(d)/E, "abcd")` returns `['cd', 'd']` (as strings in Elixir form).
- `Regex.run(~r/e/E, "abcd")` returns `nil`.
- `Regex.names(~r/(?<FOO>foo)/E)` returns `["FOO"]`.

Additionally, exported regexes should be structurally comparable to a `Regex` compiled with `:export` (for example, `~r/foo/E == Regex.compile!("foo", [:export])`).

With these changes, regex literals intended for configuration (notably Phoenix live reload patterns) can be written using the `E` modifier so that `mix release` on OTP 28 can read runtime configuration without rejecting regex values as invalid terms.