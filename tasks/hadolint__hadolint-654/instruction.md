When linting Dockerfiles that set a non-POSIX shell via the JSON-form `SHELL` instruction (e.g., Windows `cmd.exe` or `powershell.exe`), hadolint currently still runs ShellCheck-based analysis on subsequent `RUN` instructions. This causes incorrect ShellCheck parse errors and warnings because ShellCheck only supports POSIX-like shells.

For example, with a Dockerfile that uses PowerShell:

```Dockerfile
FROM golang:1.14-windowsservercore-1809
SHELL ["C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", "-Command"]
RUN Get-Variable PSVersionTable | Select-Object -ExpandProperty Value
```

hadolint emits ShellCheck errors like:

- `SC1008 This shebang was unrecognized. ShellCheck only supports sh/bash/dash/ksh. Add a 'shell' directive to specify.`
- `SC1073 Couldn't parse this function. Fix to allow more checks.`

Similarly, when using cmd:

```Dockerfile
FROM mcr.microsoft.com/powershell:ubuntu-16.04
SHELL ["cmd", "-c"]
RUN Get-Variable PSVersionTable | Select-Object -ExpandProperty Value
```

hadolint should not try to interpret the `RUN` content as a POSIX shell script.

The linter should treat a configured non-POSIX `SHELL` as an instruction to skip ShellCheck execution for subsequent `RUN` commands (until the shell is reset/changed back to a POSIX-compatible shell). This should apply to shells other than `pwsh` as well (since `pwsh` already has special handling in some cases).

Additionally, hadolint currently applies rule `DL4006` (about setting `-o pipefail` before `RUN` with pipes) even when the configured `SHELL` is non-POSIX (e.g., PowerShell or cmd), where `pipefail` is not a meaningful/valid option. In these non-POSIX shell cases, `DL4006` should not warn.

Expected behavior:
- ShellCheck-related diagnostics should not be produced for `RUN` instructions when the active `SHELL` is a non-POSIX shell such as `cmd`, `cmd.exe`, `powershell`, `powershell.exe`, or a Windows path to `powershell.exe`.
- `DL4006` should not warn for piped `RUN` commands when the active `SHELL` is a non-POSIX shell (e.g., `pwsh`, `powershell`, `cmd`).
- When the `SHELL` is POSIX-compatible (default `sh`, or `bash`, `dash`, `ksh`, etc.), existing ShellCheck behavior and `DL4006` behavior should remain unchanged.

Reproduction should succeed without ShellCheck parse errors when using non-POSIX shells, while still reporting ShellCheck findings for POSIX shells (e.g., `RUN echo $MISSING_QUOTES` under default `sh` should continue to produce ShellCheck warnings).