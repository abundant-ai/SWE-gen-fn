Dune lockfiles currently don’t support conditional actions, which are needed for package-management workflows where parts of a build/install command must only run when a filter expression holds (similar to opam’s conditional commands). Add support for a new action form `(when <condition> <action>)` inside lockfile package actions so that the nested `<action>` is executed only when `<condition>` evaluates to true. When `<condition>` evaluates to false, the action must behave as a no-op (i.e., it must not run anything and must not fail).

In addition, introduce an explicit no-op action `(nothing)` in the action language. This action must be valid anywhere an action is accepted and must perform no work. Internally, it should be usable to represent the false case of `when`, but it must also be accepted in user-authored stanzas.

The `when` action must work when nested under composite actions such as `(progn ...)`, and only the actions whose conditions are true should produce effects/output. For example, given an action like:

```
(progn
 (when (= foo foo) (run echo a))
 (when (<> foo foo) (run echo b))
 (when (<> foo bar) (run echo c))
 (when (< 1 2) (run echo d))
 (when (< 2 1) (run echo e)))
```

executing the package action should run only the `echo` commands for the true conditions, producing output:

```
a
c
d
```

and it must not run the commands whose conditions are false. The condition language must support at least equality/inequality predicates like `(= ...)` and `(<> ...)` and numeric comparisons like `(< ...)` as used above, with evaluation occurring at action execution time in the same way existing lockfile filters are evaluated.

Ensure that lockfile parsing accepts both `(when ...)` and `(nothing)`, that these forms are preserved/handled correctly by any internal representation and printing/serialization that lockfile actions go through, and that executing a false `when` (or an explicit `nothing`) never causes errors and never produces output or side effects.