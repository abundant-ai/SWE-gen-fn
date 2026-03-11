In babashka, Java interop incorrectly rejects calling instance methods on exceptions when the concrete thrown exception is a subclass of a whitelisted/allowed superclass (e.g., calling methods defined on Throwable/Exception) but the runtime class itself (e.g., java.nio.file.FileSystemException) is not explicitly allowed.

Reproduction: when a filesystem operation throws a java.nio.file.FileSystemException (for example, attempting to create directories on a read-only filesystem), catching it as Throwable and calling standard exception methods via interop fails:

```clojure
(try
  (babashka.fs/create-dirs "/Volumes/ReadOnlyVolume/minimal-repro")
  (catch Throwable t
    (println {:message (.getMessage t)})))
```

Actual behavior: babashka throws an error like:

"Method getMessage on class java.nio.file.FileSystemException not allowed!"

The same happens for other standard exception instance methods such as:

```clojure
(.getStackTrace t)
```

which currently errors with:

"Method getStackTrace on class java.nio.file.FileSystemException not allowed!"

Expected behavior: If an exception instance is of a class that extends an allowed superclass (notably Throwable), then calling instance methods that are available via that allowed superclass should be permitted. In the example above, both `.getMessage` and `.getStackTrace` should succeed on a caught Throwable whose concrete type is java.nio.file.FileSystemException, allowing the script to print the message/stacktrace and exit cleanly.

This should work generally for subclasses of Throwable, not just FileSystemException: when interop checks whether a method call is allowed, it should account for allowed superclasses/interfaces rather than requiring the concrete runtime class itself to be explicitly allowed.