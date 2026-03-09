When a workspace contains an `install` stanza that uses a `(section (site (...)))`, Dune currently performs eager package resolution while loading rules. If the referenced package is not installed/known, Dune fails early during rule loading, even when the user is not trying to run any install-related target.

This shows up in workflows like `dune build @fmt` (or any build of an unrelated target), where the build should not require optional packages referenced only by install metadata. For example, a project can declare a package `a` and also have an `install` stanza like:

```
(install
 (section (site (foobarpkg baz)))
 (files foo))

(rule
 (with-stdout-to foo (echo bar)))
```

If `foobarpkg` cannot be resolved, Dune currently errors out before it can even build `foo`, even though building `foo` does not depend on any install rules.

Dune should load rules in a directory even if some packages mentioned by `install` site sections cannot be resolved, as long as the current build does not require executing the install rules. Building a normal rule target (like `dune build foo`) should succeed and produce the expected output, regardless of whether `foobarpkg` is installed.

The missing-package condition should only become a hard error when Dune actually needs to evaluate or execute the relevant install-related rules/aliases that require that package information. In other words: missing packages referenced by install site stanzas must not prevent rule loading and unrelated builds such as `@fmt` from succeeding.