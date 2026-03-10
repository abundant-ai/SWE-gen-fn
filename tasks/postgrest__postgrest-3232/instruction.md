PostgREST’s internal observability/tracing needs to be centralized in a dedicated module (“Observation”) instead of being spread across application state and disparate call sites. The current structure makes it difficult to maintain and blocks upcoming work to control verbosity of log traces.

Introduce and wire an Observation module that becomes the single place where log trace/observation events are represented and emitted. Application startup and runtime code that currently carries or manipulates trace/log-related state in `PostgREST.AppState` should instead use this Observation module, reducing `AppState` complexity while keeping externally visible behavior the same.

After this change, constructing the application and running core operations (e.g., startup actions like schema cache loading and database version querying, and request handling paths that emit traces) must still work without changing the meaning or content of emitted messages. In particular:

- `PostgREST.App.postgrest` should be able to run with an “observation sink” that can be disabled (a callback like `const $ pure ()`) without affecting functionality.
- `PostgREST.AppState.initSockets` and other state initialization should no longer be responsible for organizing trace/log events beyond what is required for non-observability state; observability concerns should be encapsulated behind the Observation module’s interface.
- Any existing observability-related feature behavior (e.g., server timing/observability endpoints or headers, where applicable) must remain unchanged from the user’s perspective.

The goal is purely to restructure observability plumbing so that follow-up work can implement verbosity control on log traces, without changing current message behavior.