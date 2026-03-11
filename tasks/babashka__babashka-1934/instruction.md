Babashka’s Java interop is missing or incomplete for a set of generally useful Java classes and newer JDK APIs. As a result, some Java objects can’t be used smoothly from bb scripts: method invocation fails or returns unusable objects because the classes aren’t properly supported/exposed.

The following behaviors should work end-to-end when running bb code:

Calling instance methods on a virtual thread should work. When a virtual-thread-per-task executor is installed via (set-agent-send-off-executor! (java.util.concurrent.Executors/newVirtualThreadPerTaskExecutor)), evaluating @(future (.getName (Thread/currentThread))) should return an empty string (i.e., the thread name is accessible and method invocation succeeds).

Creating and inspecting virtual threads should behave correctly. The expressions:

(do
  (def t (Thread. (fn [])))
  (def vt (Thread/startVirtualThread (fn [])))
  [(.isVirtual t) (.isVirtual vt)])

should evaluate to [false true].

The JDK executor/factory types used for virtual threads should be recognized as implementing java.util.concurrent.Executor. In particular, the following should evaluate to true:

(instance?
  java.util.concurrent.Executor
  (java.util.concurrent.Executors/newThreadPerTaskExecutor
    (-> (Thread/ofVirtual)
        (.name "fusebox-thread-" 1)
        (.factory))))

Thread builder APIs for platform threads should be invokable. The chained call:

(-> (Thread/ofPlatform)
    (.daemon)
    (.start (fn []))
    (.isDaemon))

should evaluate truthy (a platform thread created with the builder is a daemon).

Additionally, bb scripts should be able to use related “generally useful” Java classes without interop errors, including:

- Unix domain sockets usage (a script that exercises domain socket support should complete and return :success).
- Byte channel and related NIO classes (a script using ByteChannel/SeekableByteChannel/etc. should complete and return :success).
- Proxying InputStream/OutputStream (a script creating proxy streams and interacting with them should complete and return :success).
- Constructing map entries via both constructors and factory methods: (clojure.lang.MapEntry. 1 2) and (clojure.lang.MapEntry/create 1 2) should compare equal to (first {1 2}).
- Working with java.security.cert.X509Certificate objects produced by CertificateFactory: after generating a certificate from an input stream, (.getSubjectX500Principal cert) should return a non-nil principal.

Currently, one or more of these scenarios fail due to missing class support in babashka’s interop layer (e.g., methods not being callable, classes not being loadable/instantiable, or returned objects not being usable). Update the interop/class exposure so these expressions and scripts run successfully and return the expected results.