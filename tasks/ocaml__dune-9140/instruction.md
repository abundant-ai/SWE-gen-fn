Concurrent `dune pkg` operations can access and modify the package revision store’s underlying git repository at the same time, which can leave the repository in an invalid/corrupted state. The revision store must ensure that only one process at a time performs operations that mutate or initialize the store.

Implement process-level locking for the revision store so that commands like `dune pkg lock` serialize access when they need to read/initialize/update the revision store. The lock should be taken when loading/creating the revision store and/or when performing operations that may mutate its git state (for example when adding a repository remote).

If acquiring the lock fails, the command must fail with a clear error message that includes the path to the lock file and the OS error. For example, when `flock` fails with `EBADFD`, `dune pkg lock` should exit non-zero and print an error of the form:

```
Error: Failed to get a lock for the revision store at
<path-to-cache>/dune/rev-store.lock:
File descriptor in bad state
```

The locking change must not break expected revision store behavior. In particular, creating a revision store and calling `Dune_pkg.Rev_store.add_repo` with a `source` pointing to a git repository should succeed, and calling `Rev_store.add_repo` again with the same `source` should also succeed (idempotent addition of the same remote).