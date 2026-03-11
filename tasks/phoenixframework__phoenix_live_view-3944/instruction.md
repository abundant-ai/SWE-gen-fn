Phoenix LiveView currently supports running asynchronous operations via APIs like `assign_async/3` and `start_async/3`, but there is no equivalent for asynchronously populating/updating a LiveView stream. Implement a new API `stream_async/3` (and `stream_async/4` with options) that allows a LiveView to start an asynchronous task whose successful result is used to update a named stream, while exposing an `AsyncResult`-style assign for loading/ok/error states.

When a LiveView calls `stream_async(socket, :my_stream, fun, opts \\ [])`, it should immediately mark an assign named `:my_stream` as loading (so it can be rendered via `<.async_result assign={@my_stream}> ... </.async_result>`), then run `fun` asynchronously. The `fun` must not access the LiveView socket; if the function body (or functions it calls) attempt to use the `socket` variable, the system must emit a warning to stderr that includes the text: "you are accessing the LiveView Socket inside a function given to stream_async" (same warning behavior as existing async APIs).

The asynchronous function is expected to return one of the following:

- `{:ok, enumerable}` where `enumerable` is an enumerable of items to insert into the stream.
- `{:ok, enumerable, stream_opts}` where `stream_opts` is a keyword list of options to control how the stream is updated (for example `at: index` to insert at a specific position, and `reset: true` to reset the stream before inserting).
- `{:error, reason}` to mark the async result as failed.

If the function returns an invalid value (for example a bare integer like `123`, or `{:ok, "not enumerable"}`), `stream_async` should not silently succeed; it must treat this as a failure and surface it through the async assign so the failure slot in `<.async_result>` can render (with a `{kind, reason}` pair), rather than crashing the LiveView process.

Error handling requirements:
- If `fun` raises (e.g. `raise "boom"`) or exits (e.g. `exit(:boom)`), the LiveView must not crash. The async assign for the stream must transition to a failed state that preserves whether it was an `:exit` or `:raise`-style failure and the associated reason.
- If `fun` returns `{:error, reason}`, the async assign must transition to failed with that reason.

Success behavior requirements:
- On `{:ok, items}` the items must be streamed into the LiveView stream identified by the given name (e.g. `:my_stream`).
- On `{:ok, items, reset: true}` the existing stream contents must be cleared before inserting the new items.
- On `{:ok, items, at: n}` the items must be inserted respecting the `:at` position behavior consistent with normal stream insertion.
- After a successful stream update, the async assign (e.g. `@my_stream`) must be in an ok/success state so `<.async_result>` renders its non-loading content.

Lifecycle/cancellation requirements:
- It must be possible to start `stream_async/3` from `mount/3` and from `handle_event/3`.
- If the LiveView terminates while a `stream_async` task is still running, the task must be cleaned up so it does not leak processes.
- If a new `stream_async` is started for the same name while a previous one is still running, the previous one should be cancelled/ignored so that only the latest result updates the stream and async state.

In summary, implement `stream_async` as a first-class async primitive analogous to `assign_async`, but whose successful result updates a stream and whose loading/ok/failed state is accessible via an assign with the same name as the stream.