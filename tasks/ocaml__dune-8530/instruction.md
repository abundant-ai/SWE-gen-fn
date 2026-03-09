When converting build errors into RPC diagnostics, the resulting user-facing message is not preserved correctly across serialization/deserialization.

In particular, creating a diagnostic from a build-system error and converting it to a user message via RPC currently changes the structure of the message such that the rendered output is wrong: a plain error like `User_error.make [ "Oh no!" ]` ends up being prefixed/duplicated, yielding output like `Error: Error: Oh no!` instead of a single `Error: Oh no!`.

This happens in the path that takes a `Dune_engine.Compound_user_error` wrapped in a diagnostic description (constructed with `Dune_engine.Compound_user_error.make ~main ~related:[]`) and then builds an RPC-ready error using `Dune_engine.Build_system_error.For_tests.make ~description ~dir ~promotion:None ()`, converts it with `Dune_rpc_impl.Diagnostics.For_tests.diagnostic_of_error`, and finally turns it into a user message with `Dune_rpc_private.Diagnostic.to_user_message`.

The RPC conversion must preserve the original `Stdune.User_message` semantics:
- For an error without a location, printing the message before and after the RPC round-trip should produce the same single-prefixed error (no duplicated `Error:` label).
- For an error with a location (e.g. created with `User_error.make ~loc (...)` where `loc` is a `Stdune.Loc`), the location information must still be present after the RPC conversion, and the human-readable rendering must match the original message.
- The structured representation of the message (as produced by pretty-printing the `Stdune.User_message` and converting it to a dynamic form) must also remain equivalent after the RPC conversion; the round-tripped message should not introduce extra nested error headers or change tags in a way that alters rendering.

Fix the logic involved in producing RPC diagnostics from build errors so that `diagnostic_of_error` + `Diagnostic.to_user_message` round-trips error messages without duplicating the top-level error prefix and without losing/changing location-bearing formatting.