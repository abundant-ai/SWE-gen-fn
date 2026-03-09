Lockdir loading behavior is implemented twice: one loader used by rule generation that memoises file IO results, and a separate loader used by unit/integration-style code paths that performs direct (non-memoized) reads. These two implementations have drifted and can behave inconsistently when reading the same lockdir from disk.

Unify lockdir loading behind a single shared implementation that can be instantiated for both use cases:

- A memoized loader used by the build/rules side so repeated reads of the same lockdir path do not re-run file IO.
- A simple non-memoized loader used by test-oriented code paths so it can load lockdirs directly without depending on rule memoization infrastructure.

The unified loader must expose the same observable lockdir contents regardless of which instantiation is used. In particular, any code consuming lockdirs through the public lockdir API (e.g., via the Dune_pkg.Lock_dir module and associated routines used by package operations) should see identical parsed results and error behavior whether the lockdir is loaded via the memoized or non-memoized path.

Fix the inconsistency by introducing a functor (or equivalent abstraction) that factors the common lockdir reading/parsing logic into one place while allowing the caller to choose the effect/memoization strategy. After this change, code that loads a lockdir in a test/scheduler context should be able to call into the same lockdir-loading logic (without memoization), and code that loads lockdirs during rule execution should use the memoized instantiation, eliminating duplicated parsing/IO logic.

Expected behavior:
- Loading the same lockdir from disk via the rules/memoized context and via the tests/direct context yields the same lockdir structure.
- Repeated loads in the memoized context do not repeat disk IO.
- Repeated loads in the direct context are allowed to re-read disk IO (no memoization requirement), but must still parse identically.
- Error messages and failure modes (e.g., invalid lockdir contents) are consistent across both contexts.