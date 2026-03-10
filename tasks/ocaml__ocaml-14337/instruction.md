There is a race in the OCaml runtime when calling `caml_callback` in the presence of effects/continuations and concurrent GC compaction across domains.

`caml_callback` temporarily stashes the caller’s (parent) stack inside a continuation block for the duration of the C-to-OCaml callback, then restores the parent stack afterwards. Under certain timing, this can produce a continuation value that becomes unreachable (“dropped”) after `caml_callback` returns, but may already have been promoted by a minor GC. Another domain doing compaction can then encounter this now-unmarked continuation and attempt to traverse the stack it points to.

The failure mode is:
- Domain 1 enters `caml_callback` and allocates a continuation that points to Domain 1’s parent stack.
- A minor collection occurs and promotes that continuation.
- Domain 1 returns from `caml_callback`, drops the continuation, and continues execution, changing return addresses on its stack.
- A different domain performs `Gc.compact ()` work and finds the promoted continuation unmarked. During compaction it traverses the continuation’s saved stack, but the saved stack contains an arbitrary/changed return address from Domain 1. If the frame table indicates registers should be visited for that return address, the runtime may attempt to dereference `gc_regs` based on invalid information and segfault.

This should not be possible: compaction must never traverse a stack snapshot that can later be mutated in-place by the domain that originally owned it.

Reproduction scenario: define an external `caml_callback : ('a -> 'b) -> 'a -> 'b = "caml_callback"`; use it to call `Gc.minor ()` from within an effect handler that creates/drops a continuation; in parallel, spawn a domain that repeatedly calls `Gc.compact ()`. Repeating this many times should not crash the runtime.

Fix `caml_callback` so that, during the callback window, the continuation/stack handling is done in a way that avoids leaving behind a continuation referring to a parent stack that can be mutated after the callback returns. In particular, `caml_callback` should use the continuation API intended for safe temporary use (e.g., `caml_continuation_use`) so the runtime swaps out the stack pointer appropriately rather than merely stashing a pointer to the parent stack in a continuation that can be promoted and later traversed by another domain.

Expected behavior: the program described above runs to completion without segmentation faults, even under heavy minor GC and concurrent `Gc.compact ()` on another domain.

Actual behavior (before the fix): the runtime can segfault during compaction when it tries to walk a saved stack from a promoted-but-dead continuation and ends up following invalid register metadata / dereferencing `gc_regs`.