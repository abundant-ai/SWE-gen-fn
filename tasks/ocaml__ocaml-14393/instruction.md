OCaml 5 allows domains/threads to run concurrently, but the common library pattern of using a lazy thunk for one-time initialization is not concurrency-safe: concurrent callers may force the same thunk at the same time, which can lead to incorrect behavior (duplicate side effects, inconsistent state, or runtime errors). Provide a standard-library solution by adding a mutex-protected lazy thunk abstraction as a dedicated module, exposed as `Lazy.Mutexed`.

Implement a type `'a Lazy.Mutexed.t` together with the following operations and semantics:

- `Lazy.Mutexed.from_val : 'a -> 'a Lazy.Mutexed.t`
  Creates an already-computed thunk. `Lazy.Mutexed.is_val` must return `true` for such values.

- `Lazy.Mutexed.from_fun : (unit -> 'a) -> 'a Lazy.Mutexed.t`
  Creates a delayed computation. Initially `Lazy.Mutexed.is_val` must return `false`.

- `Lazy.Mutexed.force : 'a Lazy.Mutexed.t -> 'a`
  Forces evaluation and returns the value.
  * Sequential sharing: forcing the same thunk multiple times must evaluate the initialization function at most once; side effects must not be repeated.
  * Exception behavior: if the initialization function raises, `force` must re-raise that exception to the caller, and the thunk must remain in a non-value state (`is_val` stays `false`) so that later calls can retry and observe the same raising behavior again.
  * Concurrency behavior (systhreads): if multiple threads call `force` concurrently on the same thunk, the initialization function must run exactly once; other forcing threads must wait until the computation completes and then return the same resulting value (or re-raise the same exception).

- `Lazy.Mutexed.is_val : 'a Lazy.Mutexed.t -> bool`
  Returns `true` exactly when the thunk holds a successfully computed value.

Also define and document the behavior for recursive forcing: if the initialization function attempts to `force` the same thunk while it is already being forced, this should not silently deadlock. On platforms where the underlying mutex implementation detects self-deadlock, this may raise (for example `Sys_error "Mutex.lock: Resource deadlock avoided"`); this behavior should be consistent with using a mutex to guard forcing.

Overall, the goal is to make this idiom safe for thread-based concurrency in OCaml 5 by providing a simple blocking implementation that ensures single evaluation under concurrent forcing, while preserving expected sequential lazy semantics and well-defined behavior on exceptions.