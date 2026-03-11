Babashka currently fails to interoperate with `java.text.BreakIterator`. Code that tries to use this class (e.g., importing it, calling its static factory methods, and then invoking instance methods on the returned iterator) does not work as expected, because the class is not available/recognized in the runtime.

Reproduce by evaluating code that uses `java.text.BreakIterator`, such as importing the class, creating an instance via one of its factory methods (for example, `BreakIterator/getWordInstance` or similar), setting text with `.setText`, and then iterating boundaries with calls like `.first`, `.next`, and `.current`. This should run without class-resolution errors and should allow invoking these methods normally from babashka.

Expected behavior: `java.text.BreakIterator` can be imported/loaded, its factory methods can be called to obtain an iterator, and instance methods can be invoked to perform boundary iteration over text.

Actual behavior: attempting to use `java.text.BreakIterator` results in failures to resolve or load the class in babashka, preventing its use for text boundary analysis.

Implement support so that `java.text.BreakIterator` is available in babashka’s Java interop environment and can be instantiated and used through its standard API (factory methods and instance methods) the same way it works on the JVM.