In babashka’s REPL, the dynamic var `*e` is intended to hold the last exception thrown during evaluation so users can inspect it (including via `(ex-data *e)`). Currently, when user code throws an `ExceptionInfo` created by `(ex-info ...)`, evaluating `*e` shows an `#error` that includes the original `:cause` and the original `:data` map, but calling `(ex-data *e)` does not return that user-provided data. Instead, `(ex-data *e)` returns only a babashka/sci error metadata map (e.g. with keys like `:type :sci/error`, `:line`, `:column`, `:file`, `:message`, and callstack info), and the user’s `{:a 1 :b 2}` is missing.

Reproduction:

```clojure
(throw (ex-info "sample error" {:a 1 :b 2}))
(ex-data *e)
```

Expected behavior: `(ex-data *e)` should return the data provided to `ex-info`, i.e. `{:a 1 :b 2}` (and similarly for computed values, e.g. `(throw (ex-info "foo" {:a (+ 1 2 3)}))` should make `(ex-data *e)` return `{:a 6}`).

Actual behavior: `(ex-data *e)` returns only interpreter/evaluation metadata and omits the user-thrown exception’s data.

Update the REPL’s exception capturing so that `*e` contains (or delegates to) the original exception thrown by user code in a way that preserves `ex-data` for `ExceptionInfo` and makes `(ex-data *e)` return the user’s data map.