Calling `Eol_detect.get_eol_for_file` repeatedly leaks file descriptors. After enough calls in the same process (often ~250 on macOS, but dependent on the OS limit), the program crashes with an exception like:

```
Fatal error: exception Sys_error("<path>: Too many open files")
```

This happens because `get_eol_for_file` opens a file to inspect its end-of-line style (LF vs CRLF) but does not reliably close the input channel on the successful (non-exceptional) path. As a result, each call consumes another file descriptor until the process reaches the OS limit.

Reproduction scenario: repeatedly call `Eol_detect.get_eol_for_file` on the same existing file in a loop (e.g., 25+ times with a low `ulimit -n`, or hundreds of times on default limits). The call should not accumulate open file handles, and the loop should complete without raising `Sys_error`.

Expected behavior: `Eol_detect.get_eol_for_file` must always close the opened channel regardless of whether it hits a newline normally, reaches `End_of_file`, or raises another exception during reading. Repeated calls should not increase the number of open file descriptors, and the loop should finish successfully.

Actual behavior: the opened channel is only closed in some exceptional cases (such as `End_of_file`), but not on the normal successful path, leading to an eventual `Sys_error("Too many open files")` crash under repeated use.