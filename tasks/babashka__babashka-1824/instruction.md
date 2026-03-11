When running babashka tasks from bb.edn, the global tasks `:init` block is not executed with the correct semantics.

There are two problems:

1) `:init` can be executed more than once during a single `bb run` invocation. This happens particularly when tasks contain nested task invocations (e.g., one task triggers another `run`-style execution). In those situations, the `:init` form is evaluated again, which breaks expectations for side-effecting initialization (e.g., setting vars, registering hooks, initializing state). `:init` must be executed at most once per `bb run` process execution, even if task execution triggers additional task evaluation internally.

2) The execution order between `:init` and task-specific `:requires` is wrong. If a task (or task map form) declares `:requires`, those namespaces may be loaded before `:init` runs. This prevents `:init` from being used to set system properties or other global configuration needed by required namespaces at load time. The correct behavior is that `:init` runs before any task-specific requires are loaded.

Expected behavior:
- Given a config like:
  ```clojure
  {:tasks {:init (do (System/setProperty "my.prop" "1") (def x 1))
           foo x}}
  ```
  running `bb run --prn foo` should print `1`.
- If a task declares `:requires`, the `:init` code must run first, so that any side effects (like setting `(System/setProperty ...)`) are visible during namespace loading.
- If a task triggers additional task execution internally, the `:init` block must not be re-run; it should remain a one-time initialization for the whole invocation.

Actual behavior:
- `:init` may be evaluated multiple times in scenarios involving tasks that invoke other tasks via run-like execution.
- Task-specific requires may be loaded before `:init`, causing namespaces that read system properties at load time to see incorrect/default values.

Fix the task runner so that `:init` is evaluated exactly once per `bb run` invocation and always before any task-specific `:requires` are processed (including requires on tasks referenced through `:depends`).