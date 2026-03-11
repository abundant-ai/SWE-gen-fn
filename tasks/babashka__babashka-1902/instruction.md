Babashka currently exposes `java.security.DigestInputStream`, but `java.security.DigestOutputStream` is not available even though it is part of the standard JDK API. Users attempting to import or use `java.security.DigestOutputStream` in Babashka encounter a class-not-found / cannot resolve class error during import or interop usage.

Reproduction example:

```clojure
(import '[java.security MessageDigest DigestOutputStream])
(require '[clojure.java.io :as io])

(let [md (MessageDigest/getInstance "SHA-256")
      baos (java.io.ByteArrayOutputStream.)
      dos (DigestOutputStream. baos md)]
  (.write dos (.getBytes "hello" "UTF-8"))
  (.flush dos)
  (.close dos)
  (seq (.digest md)))
```

Expected behavior: `java.security.DigestOutputStream` should be importable and instantiable, and writing to it should update the provided `MessageDigest` so that calling `(.digest md)` returns the correct digest for the written bytes.

Actual behavior: importing or constructing `java.security.DigestOutputStream` fails because the class is not available in Babashka’s Java interop environment.

Implement support so that `java.security.DigestOutputStream` is included/available in the same way as other supported JDK classes (including `java.security.DigestInputStream`), and interop calls on it (constructor, `write`, `on`, `getMessageDigest`/digest updates) work without errors.