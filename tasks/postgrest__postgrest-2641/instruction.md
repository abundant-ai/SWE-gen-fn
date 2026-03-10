Transaction mode selection is currently coupled to request handling in a way that requires planning to depend on schema/cache-related concerns. This prevents further refactoring work (notably reducing SchemaCache coupling in request handling and eventually removing ProcDescription from Target) because transaction mode (txMode) is determined/propagated outside of the query planning layer.

The system should treat transaction mode as part of the query plan itself. When a request is parsed and then planned, the resulting Plan must fully capture the transaction mode required to run the request. Query execution should then rely on the Plan-provided txMode rather than reading/deriving it from earlier request-processing structures.

Currently, when executing certain requests, txMode is obtained from a non-plan structure, which causes planning/execution boundaries to be leaky and makes later refactors impossible. After this change, code that executes a planned request should be able to run using only the Plan (and execution context), without needing access to the previous request object or schema-cache-derived request annotations to determine transaction semantics.

Expected behavior:
- The Plan type (or equivalent planned-request representation) includes the transaction mode information needed for execution.
- The planning entrypoint (e.g., the function that produces a Plan from a parsed request and database structure) determines the correct txMode and stores it on the Plan.
- The query execution entrypoint uses the txMode from the Plan to set up the transaction appropriately.
- No existing request types/APIs should need to retain SchemaCache dependency solely to determine txMode.
- Existing behavior around which requests run in which transaction modes must remain unchanged (i.e., no regressions in read vs write transaction handling, function/rpc requests, or other endpoints that influence txMode).

If txMode is missing or not propagated correctly, execution will either select an incorrect transaction mode or fail at runtime/compile time due to missing information at the Plan/Query boundary. The fix is complete when transaction execution consistently derives txMode from the Plan and the earlier request-processing layers no longer need to carry txMode for execution.