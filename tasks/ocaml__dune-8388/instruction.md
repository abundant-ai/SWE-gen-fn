The Dune RPC protocol needs a regression check to ensure that its serialization format for key protocol messages does not change accidentally across refactors. Currently, it’s possible to modify internal code and unintentionally change the serialized representation of RPC messages (requests/responses/notifications), which can break compatibility with older clients/servers while still allowing local tests to pass.

Add a compatibility mechanism that computes a stable digest of the serialized form of selected RPC values and compares it against an expected, committed digest. This should be done in a way that is deterministic across runs and platforms (i.e., the digest must not depend on object addresses, hash randomization, or non-deterministic ordering).

In particular, when initializing an RPC connection and exchanging the initial protocol messages, the system should be able to produce a digest representing the exact serialization output (as actually sent over the channel) and verify it matches a previously recorded value. If the serialization changes, the check should fail with a clear error indicating that the serialization artifact has changed.

The implementation should work with the existing client/server flow that uses:
- `Dune_rpc.Client.Make` and `Dune_rpc_server.Make` over an abstract channel
- client connection via `Drpc.Client.connect_with_menu ... ~f:(fun c -> ...)`
- server loop via `Drpc.Server.serve ... (Dune_rpc_server.make handler)`
- initialization values created via `Initialize.Request` fields (notably `dune_version`, `protocol_version`, and `id : Id.t` created with `Id.make (Csexp.Atom ...)`)

Expected behavior:
- Given a fixed set of representative RPC values/messages (including at least the initialization handshake messages), computing the digest of their serialized form should always yield the same digest.
- If a code change alters the actual bytes/sexps written to the RPC channel for those messages, the digest check must fail.
- Normal RPC operation (connecting, running, and shutting down the test scheduler setup) must remain behaviorally unchanged aside from the new digest verification.

Actual behavior (current):
- No automated check exists to detect a serialization-format change; refactors can inadvertently change the wire representation without immediate, targeted failures.
