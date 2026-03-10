In the OCaml toplevel, the `#show` directive (specifically when used to show a constructor of an extensible variant) prints incorrect type parameters for non-GADT constructors.

Reproduction:
1) Define an extensible type with a type parameter:
```ocaml
# type 'a t = ..;;
```
2) Add one extension constructor using that parameter name:
```ocaml
# type 'a t += A of 'a list;;
```
3) Add another extension constructor using a different type parameter name:
```ocaml
# type 'b t += B of 'b list;;
```
4) Show the constructors:
```ocaml
# #show A;;
# #show B;;
```

Actual behavior (current bug):
- `#show A` prints the constructor with a freshened/incorrect parameter, e.g. `type 'a t += A of 'a0 list` instead of preserving `'a`.
- `#show B` prints the wrong type parameter on the left-hand side, e.g. `type 'a t += B of 'b list` (mixing `'a` and `'b`) instead of consistently using `'b`.

Expected behavior:
- `#show A` should print:
```ocaml
type 'a t += A of 'a list
```
- `#show B` should print:
```ocaml
type 'b t += B of 'b list
```

This should apply specifically to non-GADT constructor extensions (e.g. `B of 'b list`) and must not break correct printing for GADT extensions such as:
```ocaml
type _ t += A : int t
```
where `#show A` should continue to print:
```ocaml
type 'a t += A : int t
```

Fix `#show_constructor` so that, when printing an extension constructor, the type parameters on the extensible type are printed consistently and correspond to the constructor’s actual type scheme, without introducing spurious fresh type variables or mixing parameter names from other extensions.