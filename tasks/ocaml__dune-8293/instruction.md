Projects can declare the Dune ctypes extension in their dune-project file using forms like:

(lang dune 3.4)
(using ctypes 0.1)

or

(lang dune 3.4)
(using ctypes 0.2)

Starting with Dune 3.11, extension versions 0.1 and 0.2 must be treated as deleted. Currently, projects that still use (using ctypes 0.1) or (using ctypes 0.2) are not rejected with the required, actionable diagnostic.

When Dune loads a dune-project file containing (using ctypes 0.1), it must fail immediately and report an error located on the version token with this exact message text (including punctuation and line breaks):

Error: Version 0.1 of the ctypes extension has been deleted in Dune 3.11.
Please port this project to a newer version of the extension, such as 0.3.
Hint: You will also need to upgrade to (lang dune 3.7).

Similarly, when a dune-project file contains (using ctypes 0.2), it must fail with the same message but with 0.2 substituted:

Error: Version 0.2 of the ctypes extension has been deleted in Dune 3.11.
Please port this project to a newer version of the extension, such as 0.3.
Hint: You will also need to upgrade to (lang dune 3.7).

The error should be attributed to the dune-project stanza location (pointing at the “0.1” / “0.2” token), and Dune should exit with a non-zero status.

After this change, only ctypes extension version 0.3 should be accepted for new ctypes behavior, and existing projects on older versions should be guided to migrate by the above message rather than proceeding, crashing, or emitting a generic “unknown version” style error.