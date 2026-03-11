PostgREST’s shutdown logic currently releases the Hasql connection pool from within the signal-handling path, and this leads to inconsistent and sometimes incomplete pool cleanup depending on platform and shutdown entrypoint.

When PostgREST is terminated (e.g., via SIGINT/Ctrl-C on Unix-like systems), the code attempts to release the pool as part of the signal handler. This has a few user-visible problems:

1) Pool release is not consistently performed across platforms and entrypoints. In particular, on non-Unix platforms (where signal handling differs) shutdown may not release the pool at all, and some non-server commands (such as the configuration dump mode) can exit without releasing the pool.

2) Pool release happens before the running application is properly interrupted. Releasing the pool while `App.run` is still active can leave in-flight connections unmanaged: any connections currently checked out may not be reclaimed by `releasePool`, so they can remain open or be closed ungracefully. This can manifest as lingering connections on the PostgreSQL side after shutdown, especially under load.

The shutdown sequence should be changed so that:

- The pool is released on every shutdown path, including non-Unix platforms and non-server commands like the config-dump mode.
- The shutdown ordering is: first interrupt/stop `App.run` (triggering normal request handling teardown), then release the pool afterward, so that checked-out connections have a chance to be returned and then properly closed.

After implementing this, terminating the server should reliably close the connection pool regardless of OS, and shutdown should not leave behind active database sessions that were in use at the moment of interruption.