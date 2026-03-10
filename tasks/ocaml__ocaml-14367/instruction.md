OCaml currently allows configuring some GC/runtime parameters via the OCAMLRUNPARAM environment variable, but only using single-letter keys. This makes it hard to add new tunables and impossible to address them by descriptive names.

Implement support for named GC parameters that can be configured in two ways:

1) Via OCAMLRUNPARAM using entries of the form `X<name>=<int>` (for example `Xmark_stack_prune_factor=100`). These named entries must be accepted alongside existing single-letter parameters.

2) Via a new standard library module `Gc.Tweak` that exposes a programmatic API for getting/setting named parameters at runtime.

The behavior should be:

- `Gc.Tweak.get name` returns the current value of the named parameter when `name` is supported, and raises `Invalid_argument` when `name` is unknown.
- `Gc.Tweak.set name value` sets the parameter to the given integer value when `name` is supported, and raises `Invalid_argument` when `name` is unknown.
- `Gc.Tweak.list_active ()` returns a list of `(name, value)` pairs for named parameters that are currently active (i.e., have been explicitly set away from their defaults). When all tweaks are reset to defaults it should return `[]`.

Runtime parameter reporting must integrate with this mechanism:

- After `Gc.Tweak.set "mark_stack_prune_factor" 100`, `Sys.runtime_parameters ()` must include the exact entry `Xmark_stack_prune_factor=100` among its comma-separated parameters.
- When the parameter is reset back to its default value, the corresponding `X...=...` entry must no longer appear in `Sys.runtime_parameters ()`.

To ensure there is at least one real tunable exposed via this mechanism, add a named parameter `mark_stack_prune_factor` corresponding to the runtime’s existing mark-stack pruning threshold factor (currently a fixed constant). The default value must match the current hardcoded behavior, and changing it via either OCAMLRUNPARAM (`Xmark_stack_prune_factor=<int>`) or `Gc.Tweak.set` must affect the runtime parameter value observed by `Gc.Tweak.get` and be reflected consistently in `Sys.runtime_parameters ()`.

Unknown names like "blorp" must reliably raise `Invalid_argument` for both `Gc.Tweak.get` and `Gc.Tweak.set`.