Babashka currently does not support interop with `java.nio.file.attribute.UserDefinedFileAttributeView`, which is part of the Java NIO file attribute APIs used to read and write extended (user-defined) file attributes. When a script running under babashka attempts to import or otherwise access this class, it fails because the class is not included in babashka’s supported class whitelist.

Babashka should allow using `java.nio.file.attribute.UserDefinedFileAttributeView` so that scripts can obtain and use this view via the standard NIO APIs (e.g., through `java.nio.file.Files/getFileAttributeView` and then calling methods on the returned view).

Expected behavior: code running in babashka should be able to `import java.nio.file.attribute.UserDefinedFileAttributeView` and successfully invoke its instance methods (as returned from NIO) without unsupported-class/interop restrictions preventing use.

Actual behavior: attempting to use `java.nio.file.attribute.UserDefinedFileAttributeView` in babashka results in an error indicating the class is not supported/allowed for interop (i.e., it is missing from the supported class set), preventing scripts that rely on extended attributes from running.

Implement support so that babashka recognizes `java.nio.file.attribute.UserDefinedFileAttributeView` as an allowed class and interop with it works as expected in typical NIO usage scenarios (obtaining the view and calling its methods).