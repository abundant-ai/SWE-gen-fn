ExUnit.CaptureLog currently formats captured log output using Logger.default_formatter/1, which makes it impossible to customize the formatting of captured logs independently of the global/default Logger formatter.

When capturing logs via ExUnit.CaptureLog (including helpers like capture_log/2 and with_log/2), it should be possible to pass a new option, :formatter, to control how log events are formatted while they are being captured.

The problem is that even if callers pass a formatter intended for capture, the capture infrastructure still uses the default formatter, so the captured string does not reflect the requested formatting.

Update ExUnit.CaptureLog so that:

- capture_log/2 accepts a :formatter option (alongside existing options like :level, :format, :metadata, :colors, etc.).
- The capture mechanism (the handler installed while capturing) respects the provided :formatter when converting log events into the captured output.
- If :formatter is not provided, behavior remains unchanged (it should continue using the existing default behavior).

Example of expected behavior:

```elixir
capture_log([formatter: my_formatter], fn ->
  Logger.info("hello")
end)
```

The returned captured string should be formatted using my_formatter (not Logger.default_formatter/1).

This option should also work with nested captures and should not leak state after failures/exits (i.e., group leader and handler cleanup behavior must remain correct).