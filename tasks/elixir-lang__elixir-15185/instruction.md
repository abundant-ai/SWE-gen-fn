In Elixir 1.19.5, projects that depend on tools like Kino/Livebook can fail to recompile (and can later fail to boot) due to a mismatch between the compile-time and runtime values of the application environment key `:dbg_callback` for the `:elixir` application.

Reproduction:
1) Create a Mix project, add `{:kino, "~> 0.19"}` to deps.
2) Call `dbg/1` in project code (for example: `def hello, do: dbg(1)`).
3) Start `iex -S mix` and run `recompile`.

Actual behavior: `recompile` raises `Mix.Error` stating that `:elixir` has a different value set for key `:dbg_callback` during runtime compared to compile time. The error includes values like:
- Compile time: `{Macro, :dbg, []}`
- Runtime: `{Kino.Debug, :dbg, [{Macro, :dbg, []}]}`
After this happens, restarting `iex -S mix` can immediately raise the same error because the runtime application env persists.

Expected behavior: Using Kino/Livebook (which may set a custom `:dbg_callback` at runtime) should not cause Mix to crash on `recompile/0` or prevent booting the project. In particular, changing `:elixir`’s `:dbg_callback` at runtime should not be treated as an invalid compile-time environment mismatch that forces users into recompiling/cleaning dependencies or disabling compile-env validation.

Fix the behavior so that runtime modification of `:dbg_callback` does not trigger the compile-time application environment mismatch error in Mix during compilation/recompilation, while keeping the rest of compile-time env validation behavior intact.