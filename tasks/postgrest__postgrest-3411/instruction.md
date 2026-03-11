The logging subsystem is inconsistent about how log levels are represented and compared. Some code paths treat log levels as raw text (or ad-hoc numeric thresholds), while others expect the configured log level to be a typed value. This leads to incorrect filtering and formatting of log output in some scenarios (for example, a message that should be suppressed at a higher minimum log level is still emitted, or a message that should be emitted is skipped), especially when the log level comes from configuration and is passed through the application state into the logger.

Unify log level handling so that the logger API and its callers use the `LogLevel` type consistently, rather than strings or mixed representations. When the application is configured with a minimum log level, the logger should correctly decide whether to emit messages based on that `LogLevel`, and log output should reflect the intended severity.

Concretely, code that constructs or uses the logger (including application initialization/state, request logging/observability hooks, and any components that emit structured logs) should pass a `LogLevel` value into the logger, and the logger should use that `LogLevel` for:

- Deciding whether to emit a message at a given severity (e.g., debug/info/warn/error should be filtered relative to the configured minimum).
- Producing consistent severity labeling in output (so downstream tooling sees stable severity values).

After this change, running the application with different configured log levels should produce the expected changes in verbosity (e.g., debug messages only appear when the minimum log level allows them), without any mismatches caused by string parsing or inconsistent comparisons.