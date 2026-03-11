Babashka’s REPL needs to support a JLine-backed “console REPL” mode and also expose additional JLine classes so they are usable from bb scripts.

Currently, attempting to run a REPL implementation that reads via JLine fails to behave correctly when driven by a `org.jline.reader.LineReader`. A new entry point is needed that can run the REPL loop using `LineReader.readLine(prompt)` rather than plain stdin, while preserving existing REPL semantics:

- There must be a function `repl-with-line-reader` that accepts an initialized SCI options/context and a `org.jline.reader.LineReader` instance.
- `repl-with-line-reader` must evaluate user input line-by-line, printing results the same way as the existing REPL. It must support multi-step sessions where previous results are available via `*1`, `*2`, etc.
- It must handle special termination and interrupt scenarios:
  - When `LineReader.readLine` throws `org.jline.reader.EndOfFileException`, the REPL should terminate cleanly.
  - When it throws `org.jline.reader.UserInterruptException` (e.g., Ctrl-C), the REPL should not crash; it should handle the interrupt and continue prompting for further input.
  - The REPL must still support quitting via the `:repl/quit` command.
- Error reporting must match existing REPL behavior: exceptions during evaluation should be printed to error output (including the exception class/message), and `*e` should be set so that evaluating `(ex-data *e)` works for `ex-info` errors.

In addition, multiple JLine classes must be available for reflective and direct use from bb code. The following classes must be loadable and usable:

- `org.jline.terminal.Terminal`
- `org.jline.terminal.TerminalBuilder`
- `org.jline.terminal.Size`
- `org.jline.reader.LineReaderBuilder`
- `org.jline.utils.AttributedString`

Creating terminals via JLine SPI must work in non-interactive/CI environments. In particular, using `TerminalBuilder` to build a dumb terminal should succeed and the resulting terminal must be closeable without error. Example usage that must work:

```clojure
(let [terminal (-> (org.jline.terminal.TerminalBuilder/builder)
                   (.dumb true)
                   (.build))]
  (try
    (and (some? (.reader terminal))
         (some? (.writer terminal))
         (string? (.getName terminal))
         (string? (.getType terminal)))
    (finally
      (.close terminal))))
```

Also, JLine utility enums must be accessible, e.g.:

```clojure
(str (org.jline.utils.InfoCmp$Capability/valueOf "clear_screen"))
;; expected: "clear_screen"
```

The problem is considered fixed when the JLine-backed REPL works with the behaviors above (clean EOF exit, non-crashing interrupt handling, correct result/error semantics), and the listed JLine classes and terminal-building flows work reliably in bb scripts, including environments without a real TTY.