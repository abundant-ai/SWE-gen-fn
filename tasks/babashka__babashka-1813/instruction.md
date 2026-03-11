Babashka’s SCI-based Java interop currently fails for several newer/edge Java interop scenarios that are expected to work when running scripts, especially when interacting with newer JDK classes and certain JDK APIs that rely on method/constructor resolution and type handling beyond basic reflection.

A set of interop use-cases should work but currently either throws at runtime (due to missing/incorrect method resolution) or returns incorrect results:

When invoking methods on virtual threads, calling instance methods such as `.getName` on the current thread inside a `future` should succeed even when the future is executed by a virtual-thread-per-task executor configured via `set-agent-send-off-executor!`. The expression `@(future (.getName (Thread/currentThread)))` should evaluate to an empty string in that setup.

Creating both platform threads and virtual threads and calling `.isVirtual` must correctly dispatch to the Java method and return boolean values. For example, evaluating `[(.isVirtual (Thread. (fn []))) (.isVirtual (Thread/startVirtualThread (fn [])))]` should return `[false true]`.

Interop must correctly handle JDK factory/builder chains and interface instance checks for returned objects. In particular, constructing an executor via `java.util.concurrent.Executors/newThreadPerTaskExecutor` with a virtual thread factory built through `(-> (Thread/ofVirtual) (.name "fusebox-thread-" 1) (.factory))` should return an object that satisfies `(instance? java.util.concurrent.Executor ...)`.

Additionally, interop should correctly support invoking and working with a few JDK/NIO and security-related APIs that rely on correct class/method handling and return-type interop:

- Domain socket related operations used from scripts should complete successfully.
- Byte channel and related NIO classes used from scripts should complete successfully.
- Proxying/wrapping `InputStream`/`OutputStream` with interop and calling through them should complete successfully.
- `clojure.lang.MapEntry` creation should behave consistently across constructors and factory methods: `(first {1 2})`, `(clojure.lang.MapEntry. 1 2)`, and `(clojure.lang.MapEntry/create 1 2)` should all be equal.
- Importing and working with `java.security.cert.X509Certificate` should succeed when generating a certificate via `CertificateFactory/getInstance "X.509"` and calling `.getSubjectX500Principal` on the resulting certificate; the principal must be non-nil.

Fix SCI interop so these expressions evaluate successfully and return the expected values, without requiring changes to user scripts.