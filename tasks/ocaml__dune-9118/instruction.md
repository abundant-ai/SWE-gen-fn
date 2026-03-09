Building a project that defines C/C++ object names in multiple stanzas can fail in a confusing or incorrect way because Dune attempts to load/consult OCaml tooling as part of validating object file names, even though this validation should be independent of OCaml. As a result, object-name validation can be coupled to OCaml availability/configuration and may not reliably produce the intended duplicate-object diagnostics.

When multiple stanzas define the same object name (for example, two separate stanzas both include `c_names foo`), Dune should deterministically reject the configuration as a name clash at the object-file level. The error must point at the second definition site and include:

- An error message of the form: `Error: Multiple definitions for the same object file "foo". See another definition at dune:9.`
- A hint message: `Hint: You can avoid the name clash by renaming one of the objects, or by placing it into a different directory.`
- A location pointing to the `foo` token in the stanza where the clash is detected.

This behavior must apply even in cases where libraries’ stub names might not overlap logically but their produced `.o` object file names would overlap; Dune should treat that as a conflict and report the same duplicate-object-file error.

Fix the object-name validation flow so it does not load or depend on OCaml in order to validate object names, while still correctly detecting and reporting duplicate object file names across stanzas with the error and hint shown above.