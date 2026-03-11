PostgREST’s interaction with the PostgreSQL connection pool is inconsistent across the codebase, with different call sites acquiring and releasing pooled connections in slightly different ways. This leads to edge-case bugs where connections are not released back to the pool (or are released inconsistently) when requests fail, time out, or exit early, and it also makes it hard to evolve pool handling (for example, storing the pool behind an indirection as discussed in #2391).

Unify all pool interaction behind two AppState helper functions, `usePool` and `releasePool`, and update all places that previously accessed the pool directly (e.g., patterns like using the pool via separate getters combined with SQL helpers) to instead go through these helpers.

Expected behavior:
- Any code path that borrows a database connection from the pool must reliably return it via `releasePool`, including on exceptions, cancellations, and early returns.
- Pool acquisition should be consistently performed via `usePool`, so the pool can be swapped/indirected later without changing call sites.
- Running the PostgREST process and exercising HTTP requests (including failing requests) should not leak connections or leave the process in a broken state due to unreleased pool resources.

Actual behavior before the fix:
- Some request/error paths can bypass the correct release logic because different modules manage pool resources differently.
- The inconsistent pool access pattern makes it easy to accidentally hold connections longer than intended, which can manifest as intermittent request hangs/timeouts under concurrent load.

Implement the refactor so that `usePool`/`releasePool` are the only way the rest of the application acquires/releases pooled resources, and ensure behavior remains correct across normal requests and failure scenarios.