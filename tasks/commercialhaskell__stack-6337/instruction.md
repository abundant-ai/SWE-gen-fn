Stack still exposes and/or partially supports the Intero workflow, even though Intero is unmaintained and should no longer be supported (Issue #6333). Users can still attempt to install or invoke Intero-related functionality and get behavior that implies Stack supports Intero, or they can hit confusing failures due to Intero’s tight GHC version bounds.

Update Stack to fully drop Intero support.

When a user attempts to use Stack in a way that previously relied on Intero (for example, trying to install the Intero package version "intero-0.1.23"), Stack should no longer treat Intero as a supported integration. The operation should either be rejected with a clear, explicit message that Intero is unsupported, or it should proceed as a normal package install without any Intero-specific handling. In either case, the user experience must not imply that Intero is a supported feature.

In particular, attempting to install "intero-0.1.23" in a freshly initialized project can fail due to unsatisfiable GHC bounds (it requires GHC >= 7.8 && < 8.2.2). In that scenario, Stack’s stderr output should include the standard guidance about resolving version constraint issues, including the recommendation text:

"To ignore all version constraints"

That recommendation must still appear in the failure output even after Intero support is removed.

Additionally, ensure that Stack’s GHCi script rendering utilities still behave correctly after removing Intero-related code paths. The following functions must continue to render commands exactly as specified:

- `scriptToLazyByteString` should serialize a composed script by separating commands with a newline.
- `cmdAdd` should render as `:add` followed by a space-separated list of modules and/or file paths, ending with `\n`. If the add-set is empty, it must render to an empty string.
- When `cmdAdd` is given file paths (as `Path Abs File` values), it must render the full file path.
- `cmdModule` should render an empty module list as exactly `:module +\n`, and for a non-empty list should render `:module + <modules...>\n` with single spaces between module names.

After these changes, there should be no remaining user-facing flags, commands, configuration options, or code paths that claim or attempt to provide Intero support.