Babashka currently cannot load the Cheshire namespace `cheshire.factory`, which prevents users from configuring Jackson `JsonFactory` processing limits (and related factory options) when using `cheshire.core` for JSON encoding/decoding.

Reproduction in a babashka REPL:
```clojure
(require '[cheshire.factory :as fact])
```
This fails with an error like:
```
java.lang.Exception: Unable to resolve classname: com.fasterxml.jackson.dataformat.smile.SmileFactory
```
The expected behavior is that `(require '[cheshire.factory :as fact])` succeeds in babashka, and the public API of `cheshire.factory` is usable for configuring the underlying Jackson factories used by Cheshire.

After the fix, babashka should support the `cheshire.factory` namespace sufficiently to:

- Allow creating/obtaining the JSON factory used by Cheshire without attempting to load unsupported Jackson dataformat classes (e.g., Smile) that are not included in babashka.
- Allow users to adjust factory options/limits (the “processing limits” knobs introduced in newer Jackson versions and exposed via `cheshire.factory`) such that JSON encoding/decoding honors those configured limits.
- Ensure `cheshire.core` operations like `encode`, `decode`, `generate-stream`, and `parse-stream` (where available) continue to work while respecting the configured factory settings.

A concrete requirement is that users can configure stricter limits (for example, limits that cap nesting depth or string length) and then decoding input that exceeds those limits should fail with an exception, while decoding input within those limits should succeed. Conversely, with relaxed limits, the same inputs should decode successfully.

The implementation should align with Cheshire’s intended usage pattern of dynamically configuring the JSON factory (including through dynamic vars, where applicable), so that configuration can be applied per call or via bindings, rather than requiring a global JVM-level change.