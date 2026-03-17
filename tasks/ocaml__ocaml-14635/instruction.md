There is a control-flow bug in the runtime function `caml_floatarray_gather` when gathering an empty float array.

When `size == 0`, the function currently assigns `res = Atom(0)` (the shared static empty value), but then incorrectly continues into the non-empty allocation path and allocates a block with `Double_array_tag` of size 0 anyway. This means the result is an allocated block (tag 254) instead of the expected shared atomic empty block (tag 0).

This causes empty float arrays produced via the floatarray gather path to not be physically identical to the canonical empty float array value, breaking expectations that empty float arrays compare as the same value (e.g., `a = Stdlib.Float.Array.create 0` should hold for results that are logically empty).

Fix `caml_floatarray_gather` so that when `size == 0`, it returns the canonical empty value (`Atom(0)`) without falling through to allocate a `Double_array_tag` block. After the fix, any operation that results in an empty float array through this code path must yield the shared empty representation rather than a freshly allocated empty block.