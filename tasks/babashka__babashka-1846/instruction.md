Requiring `cheshire.generate` in babashka currently fails with an error like `Unable to resolve classname: com.fasterxml.jackson.core.JsonGenerator`. This prevents users from extending Cheshire encoders via `cheshire.generate/add-encoder`, which is the standard mechanism in Cheshire for encoding custom Java types.

In particular, users should be able to define and register an encoder for `java.time.Instant` and then successfully call `cheshire.core/generate-string` on data structures containing `Instant` values without doing a pre-walk conversion.

Example that should work in babashka:

```clj
(require '[cheshire.core :as c]
         '[cheshire.generate :as cg])

(import '(java.time Instant))

(cg/add-encoder Instant
                (fn [obj writer]
                  (cg/encode-str (str obj) writer)))

(def data {:created-at (Instant/now)})

(c/generate-string data)
```

Expected behavior: the `(require '[cheshire.generate :as cg])` form succeeds, `cg/add-encoder` successfully registers the encoder, and `(c/generate-string data)` returns JSON where `:created-at` is encoded as a string (e.g. an ISO-8601 instant). Parsing that JSON back with `cheshire.core/parse-string` (with keyword keys) should yield a map whose `:created-at` value is a string that can be round-tripped via `java.time.Instant/parse`.

Actual behavior: requiring `cheshire.generate` fails due to the missing/unsupported `com.fasterxml.jackson.core.JsonGenerator` class in the babashka runtime, making custom encoder registration unusable.

Fix this by ensuring the required Jackson core API (specifically `com.fasterxml.jackson.core.JsonGenerator`) is available in babashka so that `cheshire.generate` can be loaded and custom encoders can be used at runtime.