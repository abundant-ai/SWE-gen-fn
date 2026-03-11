There is a correctness bug when `with-redefs` is used together with `intern` in babashka. In Clojure, `with-redefs` temporarily changes the root binding of an existing Var for the dynamic scope of its body, and those changes should be visible to any lookups of that Var performed during the `with-redefs` body.

In babashka, when code calls `intern` while a Var is temporarily redefined via `with-redefs`, the interned Var resolution can become inconsistent: lookups during the `with-redefs` body may still return the original root value (or a different Var instance) instead of the temporary value. This can show up as functions not being overridden as expected, or as calls continuing to hit the original implementation even though `with-redefs` appears to have succeeded.

Repro scenario:

```clojure
(defn f [] :orig)

(with-redefs [f (fn [] :patched)]
  ;; Any code path that interns or resolves the symbol `f` during this body
  ;; must see the patched value.
  (intern *ns* 'g (fn [] (f)))
  (g))
```

Expected behavior: within the `with-redefs` body, calling `(f)` returns `:patched`, and any function or Var created via `intern` that refers to `f` during that scope should observe the patched `f`. After exiting `with-redefs`, `f` should return `:orig` again and `with-redefs` should not permanently change the Var.

Actual behavior: during the `with-redefs` body, an `intern`-related path can cause `f` to resolve to the original value (or otherwise bypass the temporary redefinition), so `(g)` may return `:orig` (or fail to respect the override).

Fix babashka’s handling of `with-redefs` and `intern` so that:
- `with-redefs` consistently affects all Var lookups during its dynamic scope, including lookups performed as part of `intern` and subsequent symbol/Var resolution.
- `intern` does not introduce a separate Var identity or cached resolution that ignores the temporary rebinding.
- After the `with-redefs` body completes (even when exceptions occur), original root bindings are restored reliably.

The fix should ensure correct behavior for both function Vars and non-function Vars, and for repeated `intern`/resolution operations occurring inside a single `with-redefs` scope.