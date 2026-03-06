`postgrest-watch postgrest-build` can enter a failure loop during iterative development, repeatedly aborting builds with a Cabal package DB creation error:

```
ghc-pkg: cannot create: .../dist-newstyle/.../package.conf.inplace already exists
Error: [Cabal-7125]
Failed to build postgrest-... (lib/test/exe ...)
```

After this starts happening, the watcher does not recover on its own; developers must stop it (Ctrl+C) and restart, which significantly slows refactoring work. Cleaning build artifacts (`rm -rf dist-newstyle`, `git clean -xdf`) does not prevent the issue from reoccurring.

The host resolution / network-related logic is duplicated across the networking layer and the observation/metrics layer, and the refactor should deduplicate this while preserving correct behavior. After the deduplication, the build/watch workflow must remain stable: running `postgrest-watch postgrest-build` repeatedly while source files change should not cause Cabal to end up in a state where it tries to create an already-existing `package.conf.inplace` and fails continuously.

Implement the deduplication in a way that preserves existing observable behavior of network/host resolution and observations, and ensure the refactor does not introduce concurrency/re-entrancy issues or repeated initialization that can trigger the above Cabal failure during watch rebuilds. The final behavior should be that developers can keep `postgrest-watch postgrest-build` running across many recompiles without needing to restart it due to `package.conf.inplace already exists` errors.