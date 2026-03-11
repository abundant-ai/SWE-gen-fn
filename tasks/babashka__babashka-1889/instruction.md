Babashka currently cannot reify the Java interface `java.time.temporal.TemporalField`. When attempting to create a reified implementation of this interface, compilation fails with an error like:

`Syntax error (ClassNotFoundException) compiling new ... babashka.impl.java.time.temporal.TemporalField`

This prevents users from writing code such as `(reify java.time.temporal.TemporalField ...)` even though `TemporalField` is part of the standard Java time API.

The system should allow `reify` to target `java.time.temporal.TemporalField` without requiring a non-existent babashka-prefixed class (e.g., it should resolve the real JDK type correctly at compile time and generate a working reified instance).

In addition, `java.time.temporal.ValueRange` should be supported as a whitelisted/available Java class so that scripts using it do not fail due to missing/blocked class access.

After the fix, creating reified objects for existing supported interfaces (e.g., `java.io.FileFilter`, `java.io.FilenameFilter`, `clojure.lang.ILookup`, `clojure.lang.IFn`, and `Object` with overrides like `toString`, `equals`, and `hashCode`) must continue to behave correctly, including support for multiple arities in reified methods (e.g., `valAt` with 2 and 3 arguments; `invoke` with varying arities plus `applyTo`).