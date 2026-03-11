OCaml currently emits Warning 37 [unused-constructor] for variant constructors that are defined/implemented as private (for example, `type a = private A`). This is problematic for a common GADT-indexing style recommended for OCaml trunk (future 5.5): using private constructors to give abstract index types a generative identity when abstract `type a` indices no longer behave as before.

The problem is that private constructors used purely as type-level indices are intentionally not used to construct values (they are effectively un-constructible outside the defining scope), but the compiler still warns that they are unused. This produces noisy and misleading warnings for code like:

```ocaml
type a = private A
type b = private B

type _ t =
  | KA : a t
  | KB : b t
```

Expected behavior: when a constructor is private in its definition/implementation (e.g., `type t = private T` or `type a = private A`), the compiler should not emit the unused-constructor warning for that constructor merely because it is never used to build values.

Actual behavior: the compiler emits Warning 37 stating the constructor is unused (or “never used to build values”), even though the private constructor is serving its intended purpose as a type-level tag.

This change should only silence warnings for constructors that are private in the type definition/implementation. It should not remove warnings for normal (non-private) constructors.

Additionally, the existing behavior for exported private types should remain sensible: if a type is exported as a private variant (e.g., a signature exposes `type t = private T` while the implementation defines `type t = T`), the warning message about not being used to build values may still be appropriate. The key requirement is that private constructor definitions/implementations used as generative indices should not trigger unused-constructor warnings.