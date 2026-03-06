Code using the uncurried ST function helpers is currently missing support for constructing and running ST functions in a way that compiles down to efficient JavaScript calls.

Implement the "mkST" and "runST" family of functions for uncurried ST actions, matching the existing uncurried API style used elsewhere.

In particular, the module `Control.Monad.ST.Uncurried` should provide:

- `STFn1`, `STFn2` types representing uncurried ST computations of arity 1 and 2.
- Constructors `mkSTFn1` and `mkSTFn2` that turn functions like `\a -> pure (...)` and `\a b -> pure (...)` into `STFn1`/`STFn2` values.
- Runners `runSTFn1` and `runSTFn2` that take an `STFn1`/`STFn2` plus its arguments and produce an `ST r a` action.

Expected behavior:

- Given definitions like:
  ```purescript
  mySTFn1 :: forall r. STFn1 Int r Int
  mySTFn1 = mkSTFn1 \a -> pure (a + 1)

  mySTFn2 :: forall r. STFn2 Int Int r Int
  mySTFn2 = mkSTFn2 \a b -> pure (a + b)

  myInt1 :: forall r. ST r Int
  myInt1 = runSTFn1 mySTFn1 0

  myInt2 :: forall r. ST r Int
  myInt2 = runSTFn2 mySTFn2 0 1
  ```
  the compiled JavaScript should represent `mySTFn1` and `mySTFn2` as plain uncurried JS functions, and `runSTFn1`/`runSTFn2` should compile down to direct calls like `mySTFn1(0)` and `mySTFn2(0, 1)` without extra wrapper allocations.

- The above should also work when calling `runSTFn1`/`runSTFn2` inside `do`-notation, and composed ST actions should produce correct integer results.

Actual behavior to fix:

- The `Control.Monad.ST.Uncurried` API is incomplete (missing `mkSTFnN`/`runSTFnN` and/or correct types), and/or the compiler does not recognize these helpers for optimization, resulting in either compilation failures (missing identifiers/types) or non-optimized JavaScript that doesn’t emit direct uncurried calls.

After implementing this, code using `mkSTFn1`/`mkSTFn2` and `runSTFn1`/`runSTFn2` should compile successfully and produce efficient uncurried JavaScript calls while preserving correct ST semantics.