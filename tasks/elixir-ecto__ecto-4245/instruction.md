`Ecto.Repo.preload/3` currently spawns processes while preloading associations (to run multiple preload queries concurrently). There is no supported way to control how those preload tasks are spawned/linked/monitored, which makes it hard for callers to integrate preloading into their own supervision or failure-handling strategy.

Add a new `:on_preload_spawn` option to `Repo.preload/3` (and the underlying preload entrypoints it calls) that allows callers to customize what happens whenever the preload mechanism is about to spawn work.

When `Repo.preload/3` is called with `on_preload_spawn: fun`, the preloader must call `fun` to spawn the preload work instead of using its default spawn behavior. The function will be used for each spawned preload job and must be invoked in a way that preserves the existing semantics of `Repo.preload/3`: it should still return the same preloaded structs, in the same shape (single struct, list of structs, nested preloads, etc.), and it must still propagate errors in the same way as before.

If `:on_preload_spawn` is not provided, `Repo.preload/3` must behave exactly as it does today.

`Repo.preload/3` should also validate the option: passing a non-function value for `:on_preload_spawn` must raise an `ArgumentError` with a clear message indicating that `:on_preload_spawn` must be a function.

Example usage that should work:

```elixir
Repo.preload(struct_or_structs, [:assoc], on_preload_spawn: fn fun ->
  Task.async(fun)
end)
```

In this example, preloading should still complete successfully and return properly preloaded data, but the actual concurrency primitive used to run preload work is delegated to the given callback.
