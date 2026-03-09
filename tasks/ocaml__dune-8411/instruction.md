When Dune RPC diagnostics are serialized and then deserialized back into a user-facing message, the resulting message incorrectly contains a duplicated severity prefix. In particular, a diagnostic originating from a user error like `User_error.make [ Pp.verbatim "Oh no!" ]` is rendered originally as:

`Error: Oh no!`

but after converting it through the RPC diagnostic pipeline it becomes:

`Error: Error: Oh no!`

This happens because the initial user message content being serialized still includes the textual severity prefix (e.g. `"Error:"`), while the diagnostic data also separately records the severity (e.g. Error). During rendering after deserialization, the severity is applied again, producing two prefixes.

Fix the RPC diagnostic conversion so that severity is not duplicated after a round-trip. Specifically, when building/serializing the diagnostic that will be sent over RPC (e.g. via `Dune_rpc_impl.Diagnostics.For_tests.diagnostic_of_error` and then rendered via `Dune_rpc_private.Diagnostic.to_user_message`), ensure the serialized message content does not retain a leading `"Error:"` (and analogous severity prefixes) when the diagnostic already carries severity information.

After the fix, round-tripping a diagnostic through RPC must preserve the original single-prefix rendering for plain messages and also for messages that include locations (e.g. errors created with `User_error.make ~loc ...`), so that the displayed/pretty-printed structure and the plain text rendering do not show an extra nested `Error`/`Error:` prefix.