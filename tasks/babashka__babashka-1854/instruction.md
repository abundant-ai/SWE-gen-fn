`ring.middleware.resource/wrap-resource` (and other libraries that rely on `ring.util.response/get-resources`) fails in babashka because `(-> (.getContextClassLoader (Thread/currentThread)) (.getResources "public") (enumeration-seq))` returns an empty sequence even when the directory exists on the babashka classpath. In standard Clojure with an equivalent `resources/public` directory on the classpath, the same call returns a URL for the `public` directory, enabling Ring to discover resources and serve them.

Reproduction:
1) Create a project with both `src` and `resources` on the classpath and a resource directory `resources/public` containing at least one file, e.g. `resources/public/file.txt`.
2) Confirm that `(clojure.java.io/resource "public/file.txt")` returns a valid URL in babashka.
3) Call `(-> (.getContextClassLoader (Thread/currentThread)) (.getResources "public") (enumeration-seq))` in babashka.

Expected behavior: the thread context classloader should represent the effective babashka classpath so that `.getResources` can enumerate classpath directories and jar entries consistently with Clojure. In particular, `.getResources "public"` should return a non-empty enumeration that includes a URL to the `public` directory when it exists on the classpath.

Actual behavior: in babashka, `.getResources "public"` returns nothing even though `public/file.txt` is resolvable via `clojure.java.io/resource`, which causes middleware like `ring.middleware.resource/wrap-resource` to not find resources rooted at `public`.

Fix the discrepancy by ensuring that the thread `ContextClassLoader` used during babashka execution is set up to reflect babashka’s current classpath (including additions made via CLI `--classpath` and runtime classpath APIs). After the fix, code that relies on `(or loader (.getContextClassLoader (Thread/currentThread)))` and calls `.getResources` should be able to discover classpath roots/directories the same way it does on the JVM Clojure runtime.