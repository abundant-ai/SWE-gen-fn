Repeatedly detecting end-of-line (EOL) style for the same file can leak file descriptors or otherwise fail to release resources properly.

When calling `End_of_line.Detect.get_eol_for_file` many times in a loop on the same input path (e.g., 20+ invocations), the operation should complete without exhausting the process file-descriptor limit and without leaving open handles. Currently, repeated calls can accumulate open descriptors and eventually cause failures such as “Too many open files” (or platform-equivalent errors), especially in long-running tooling that formats many files.

The function `End_of_line.Detect.get_eol_for_file` is expected to:

- Read enough of the target file to determine its EOL convention (LF vs CRLF, and any other supported modes), returning a consistent result for the same file contents.
- Properly close any opened file descriptors/channels on all paths (success, early exit once EOL is determined, and error cases).
- Be safe to call repeatedly without increasing the number of open file descriptors over time.

A simple reproduction is to invoke `End_of_line.Detect.get_eol_for_file "./input.re" |> ignore` in a loop dozens of times; this should reliably finish and print a final confirmation, rather than failing due to leaked resources.