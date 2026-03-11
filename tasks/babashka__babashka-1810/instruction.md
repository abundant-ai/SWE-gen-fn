Java virtual-thread related interop is currently broken in babashka when using the JDK 21 virtual thread builder API and virtual-thread executors.

When running code that uses virtual threads, certain method invocations and builder chaining should work but currently fail due to incorrect interop handling of the involved JDK types.

The following scenarios must work:

1) Using a virtual-thread-per-task executor as the send-off executor for futures should allow invoking methods on the running thread. For example, after calling:

```clojure
(set-agent-send-off-executor!
  (java.util.concurrent.Executors/newVirtualThreadPerTaskExecutor))
@(future (.getName (Thread/currentThread)))
```

The expression should evaluate successfully and produce the current thread’s name (an empty string is acceptable if that’s what the underlying thread name is), rather than throwing an interop exception.

2) Creating a platform thread with `(Thread. ...)` and a virtual thread with `Thread/startVirtualThread` should allow calling `(.isVirtual ...)` on both threads, producing `false` for the platform thread and `true` for the virtual thread:

```clojure
(def t (Thread. (fn [])))
(def vt (Thread/startVirtualThread (fn [])))
[(.isVirtual t) (.isVirtual vt)]
```

3) Chaining calls on the virtual-thread builder returned by `(Thread/ofVirtual)` must interop correctly, including calling `.name` with both a prefix string and an integer (the “starting” index), and then calling `.factory` to obtain a `ThreadFactory`. That `ThreadFactory` must be usable to create an Executor via `Executors/newThreadPerTaskExecutor`, and the resulting object must satisfy `instance? java.util.concurrent.Executor`.

Example:

```clojure
(instance?
  java.util.concurrent.Executor
  (java.util.concurrent.Executors/newThreadPerTaskExecutor
    (-> (Thread/ofVirtual)
        (.name "fusebox-thread-" 1)
        (.factory))))
```

Currently, these patterns fail because babashka’s Java interop does not correctly resolve/invoke methods on the virtual thread builder / related virtual-thread types (including overloaded methods like `.name(String,int)` and fluent chaining that returns builder types). The fix should ensure these method calls resolve to the correct overloads and execute without throwing, and that the returned objects are the correct JDK types to be used by subsequent calls (e.g., `.factory` returning a `java.util.concurrent.ThreadFactory`).