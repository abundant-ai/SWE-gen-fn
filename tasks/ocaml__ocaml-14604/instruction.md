The OCaml compiler can crash during type-checking with a fatal, uncaught exception `Ctype.Cannot_apply` when certain combinations of unboxed type definitions, type constraints, and explicitly polymorphic (locally abstract / forall) annotations are used.

A minimal reproducer is:

```ocaml
type[@unboxed] 'a foo = { foo : 'b } constraint 'a = 'b * 'c

let bar : 'c. (unit * 'c) foo = { foo = () }
```

On affected versions (reported on 5.5.0~alpha1), compiling or evaluating this code results in:

```
Fatal error: exception Ctype.Cannot_apply
```

This should not crash the compiler. The declaration of `bar` should type-check successfully and `bar` should be given a type equivalent to:

```ocaml
val bar : (unit * 'c) foo
```

The crash is specifically tied to:
- the type being marked `[@unboxed]`, and
- the explicit rank-1 polymorphic annotation on `bar` using `:'c.`.

In addition to the direct reproducer above, a closely related scenario should also work without crashing: defining an unboxed record type whose field contains an explicitly polymorphic type using the previously defined unboxed constrained type, and then using that type through type aliases and record wrappers. The compiler should accept these declarations and print their types normally, without raising `Ctype.Cannot_apply`.

Fix the type-checking logic so that `Ctype.Cannot_apply` is not raised in these cases (and is not allowed to escape uncaught). The code should be accepted and typed as expected, matching the behavior of OCaml 5.4.1 (i.e., no crash).