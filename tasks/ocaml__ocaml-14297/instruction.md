The OCaml type checker currently produces non-deterministic output in some typing error messages, depending on hash-table iteration/randomization and incidental ordering effects. This shows up most clearly in errors about non-regular recursive types in mutually recursive modules/objects/variants: the compiler reports the same underlying error, but the sequence/order of “following expansion(s)” and nested “contains …” explanations can vary between runs or between compilers built with different runtime hash randomization behavior.

When compiling recursive module definitions that introduce an irregular recursive type, the compiler should produce a stable, deterministic error message across runs. In particular, the explanation block that lists expansions (e.g. a chain like “X = …, … contains …” leading to a use such as “'a list A.t”) must appear in a consistent order, and should not depend on hash table iteration order.

For example, in a program where a recursive module defines a type constructor `A.t` as `type 'a A.t` but it is later used as `'a list A.t` through expansions involving object types (with methods like `m` and `n`) and/or polymorphic variant/object field collections, the error message should deterministically:

- State that the recursive type is not regular.
- Show the definition form `type 'a A.t`.
- Show the mismatching use form like `'a list A.t`.
- Provide a deterministic, repeatable ordering of the expansion chain(s) leading from an alias (e.g. `'a B.t = < m : 'a list A.t; n : 'a array A.t >`) to the contained problematic occurrence (e.g. “< ... > contains 'a list A.t” or “< ... > contains 'a list B.t, 'a list B.t = 'a list A.t”).

Currently, the same input can produce different orderings of these expansions, which causes unstable reference outputs and makes compiler behavior harder to reproduce. Ensure that the internal collection/accumulation logic used by the type checker for these expansion traces does not rely on randomized hash tables or other non-deterministic iteration, so the emitted diagnostic text is stable across runs and environments (including bootstrap vs non-bootstrap compilers).