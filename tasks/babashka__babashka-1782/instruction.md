Babashka currently exposes `java.nio.file.attribute.PosixFilePermissions`, but scripts that need to read POSIX permissions from existing files cannot do so because `java.nio.file.attribute.PosixFileAttributes` is not available. This prevents using the standard Java NIO API to load POSIX attributes in bulk and inspect permissions (e.g., checking whether `PosixFilePermission/OTHERS_READ` is present).

When running code that imports and uses `java.nio.file.attribute.PosixFileAttributes` (typically via `java.nio.file.Files/readAttributes`), babashka should allow the class to be imported and used just like on a regular JVM. The goal is that users can read a file’s permissions from an existing path and then inspect the returned permission set.

Example scenario that should work in babashka:

```clojure
(import '[java.nio.file Files Paths LinkOption]
        '[java.nio.file.attribute PosixFileAttributes PosixFilePermission])

(let [p (Paths/get "/tmp/some-file" (make-array String 0))
      ^PosixFileAttributes attrs (Files/readAttributes p PosixFileAttributes (make-array LinkOption 0))
      perms (.permissions attrs)]
  (.contains perms PosixFilePermission/OTHERS_READ))
```

Expected behavior: the import succeeds; `Files/readAttributes` can return a `PosixFileAttributes` instance; calling `.permissions` returns a set of `PosixFilePermission` values that can be queried (e.g., for `OTHERS_READ`).

Actual behavior before this change: attempting to import or use `java.nio.file.attribute.PosixFileAttributes` fails in babashka (class not available/whitelisted), making it impossible to read POSIX permissions for an existing file via the NIO attributes API.
