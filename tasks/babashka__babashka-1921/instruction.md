Babashka’s Java interop currently does not support the exception class `java.nio.file.FileSystemNotFoundException`. This breaks code that uses `java.nio.file.FileSystems/getFileSystem` (or other NIO filesystem APIs) and needs to detect whether a filesystem for a given URI has already been created.

In standard JVM Clojure/Java, calling `FileSystems/getFileSystem` with a URI for which no filesystem exists throws `java.nio.file.FileSystemNotFoundException`. User code commonly relies on this behavior to implement a “check-then-create” flow, e.g.:

```clojure
(import '[java.net URI]
        '[java.nio.file FileSystems]
        '[java.nio.file FileSystemNotFoundException])

(let [uri (URI. "jar:file:/tmp/app.jar")]
  (try
    (FileSystems/getFileSystem uri)
    :exists
    (catch FileSystemNotFoundException _
      :missing)))
```

In babashka, referencing/importing `java.nio.file.FileSystemNotFoundException` or attempting to catch it fails because the class is not available/supported in the runtime’s allowed Java classes. As a result, scripts that correctly handle the “filesystem does not exist yet” case cannot be written safely (the only workaround is catching overly broad exceptions like `RuntimeException`, which can mask unrelated failures).

Add support for `java.nio.file.FileSystemNotFoundException` so that:

- `(import java.nio.file.FileSystemNotFoundException)` works in babashka.
- `(catch java.nio.file.FileSystemNotFoundException e ...)` works and catches the exception thrown by `java.nio.file.FileSystems/getFileSystem` when the filesystem is missing.
- The exception behaves like on the JVM: it should be thrown and catchable as a `RuntimeException` subtype, preserving its identity and allowing precise exception handling.
