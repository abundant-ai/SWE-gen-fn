In Dune language 3.9, using the variable %{deps} inside a (cat ...) action fails when the rule has more than one dependency. For example, a rule like:

(rule
 (alias foo)
 (deps a b)
 (action (cat %{deps})))

should be valid because the cat action accepts multiple arguments/paths, and %{deps} can expand to multiple values. However, running dune build @foo currently fails with an error like:

Error: Variable %{deps} expands to 2 values, however a single value is expected here. Please quote this atom.

The bug is that (cat ...) incorrectly treats its argument position as requiring a single value, so multi-value variable expansion is rejected.

Update the action expansion/validation so that within (cat ...), %{deps} expands to all dependency paths (in order) and is accepted as multiple arguments. After the fix, dune build @foo should succeed when (cat %{deps}) is used with two or more deps, without requiring quoting tricks, while preserving existing behavior for contexts that truly require a single value.