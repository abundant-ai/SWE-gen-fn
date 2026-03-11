Babashka currently fails in an unfriendly/incorrect way when loading a project bb.edn that is empty or contains more than one top-level form.

1) Empty bb.edn should be treated as a valid “no config” case.
When a bb.edn file exists but is empty (0 bytes or only whitespace), invoking babashka with options that cause it to load bb.edn (e.g. `bb -Sdeps ''`) currently errors during config loading with an exception like:

```
Error during loading bb.edn:
Exception in thread "main" java.lang.RuntimeException: EOF while reading
```

Expected behavior: an empty bb.edn should behave the same as if bb.edn did not exist, or as if it contained an empty map `{}`. The command should proceed without failing due to EOF.

2) bb.edn must contain at most one valid EDN form.
If bb.edn contains multiple top-level forms (for example two maps, or a map followed by another form), babashka should not silently accept/partially read it. Instead it should error explicitly indicating that bb.edn is invalid because it contains more than one form.

Expected behavior: reading bb.edn validates that there is either:
- no forms (empty/whitespace-only file), or
- exactly one EDN form (typically a map)

If there is more than one form, babashka should throw an error during loading bb.edn (with a clear message) rather than continuing with ambiguous configuration.

Implement this behavior in the bb.edn reader (the function named `read-bb-edn`) so that:
- empty bb.edn does not throw
- single-form bb.edn is accepted
- multi-form bb.edn produces a deterministic error during loading bb.edn.